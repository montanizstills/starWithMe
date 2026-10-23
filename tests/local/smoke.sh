#!/usr/bin/env bash
# Smoke tests for the Local epic: checks every committed feature of the
# containerized Canvas stack. Run from anywhere; needs the stack up for the
# runtime section (./start.sh --local, or docker compose up -d).
#
#   tests/local/smoke.sh            # all sections
#   tests/local/smoke.sh static     # repo + compose only, no containers needed
#   tests/local/smoke.sh image      # built image only
#   tests/local/smoke.sh runtime    # running stack only

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

JOB_TIMEOUT="${JOB_TIMEOUT:-60}"
PASS=0
FAIL=0
FAILED=()

pass() { PASS=$((PASS + 1)); printf '  \033[32m✔\033[0m %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); FAILED+=("$1"); printf '  \033[31m✘\033[0m %s\n' "$1"; [ -n "${2:-}" ] && printf '      %s\n' "$2"; }
check() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$name"; else fail "$name"; fi; }
section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

dc() { docker compose "$@"; }
in_image() { dc run --rm --no-deps -T --entrypoint "$1" web "${@:2}"; }
rails_runner() { dc exec -T web bundle exec rails runner "$1" 2>/dev/null; }

static_tests() {
  section "Static: repo and compose"

  check "HeyGen service extracted (no src/)" test ! -e src
  check "HeyGen service extracted (no pom.xml)" test ! -e pom.xml
  check "compose file is valid" dc config -q

  local services
  services="$(dc config --services 2>/dev/null | sort | tr '\n' ' ')"
  if [ "$services" = "db jobs redis web " ]; then
    pass "compose services are db, jobs, redis, web"
  else
    fail "compose services are db, jobs, redis, web" "got: $services"
  fi

  if dc config --format json 2>/dev/null | tr -d ' \n' | grep -q '"command":\["jobs"\]'; then
    pass "jobs service runs entrypoint in jobs mode"
  else
    fail "jobs service runs entrypoint in jobs mode"
  fi

  check "entrypoint seeds DB before compiling assets" \
    awk '/db:initial_setup/ {db=NR} /canvas:compile_assets/ {ca=NR} END {exit !(db && ca && db < ca)}' entrypoint.sh
  check "entrypoint uses separate first-run flags" grep -q '/data/.db_setup_complete' entrypoint.sh
}

image_tests() {
  section "Image: build dependencies"

  local node_major
  node_major="$(in_image node -p 'process.versions.node.split(".")[0]' 2>/dev/null | tr -d '\r')"
  if [ -n "$node_major" ] && [ "$node_major" -ge 20 ]; then
    pass "Node.js >= 20 (found $node_major)"
  else
    fail "Node.js >= 20" "found: ${node_major:-none}"
  fi

  local missing
  missing="$(in_image dpkg-query -W -f='${Package}\n' \
    zlib1g-dev libldap2-dev libsqlite3-dev libyaml-dev libxmlsec1-dev pkg-config 2>&1 | grep -i 'no packages' || true)"
  if [ -z "$missing" ]; then pass "native gem build libs installed"; else fail "native gem build libs installed" "$missing"; fi

  local env
  env="$(in_image env 2>/dev/null)"
  if grep -q '^BUNDLE_APP_CONFIG=/canvas/.bundle$' <<<"$env" && grep -q '^BUNDLE_PATH=/canvas/vendor/bundle$' <<<"$env"; then
    pass "bundler config and gems point into the shared volume"
  else
    fail "bundler config and gems point into the shared volume"
  fi
}

runtime_tests() {
  section "Runtime: running stack"

  local svc
  for svc in web jobs db redis; do
    if [ "$(dc ps --status running --services 2>/dev/null | grep -cx "$svc")" = 1 ]; then
      pass "$svc is running"
    else
      fail "$svc is running"
    fi
  done
  check "db is healthy" sh -c "docker compose ps db --format '{{.Health}}' | grep -qx healthy"

  check "first-run DB setup flag present" dc exec -T web test -f /data/.db_setup_complete
  check "first-run asset compile flag present" dc exec -T web test -f /data/.setup_complete
  check "redis.yml points at the redis service" dc exec -T web grep -q 'redis://redis:6379' config/redis.yml

  local code
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 30 http://localhost:3000/login/canvas)"
  if [ "$code" = 200 ]; then pass "web serves /login/canvas (200)"; else fail "web serves /login/canvas (200)" "got HTTP $code"; fi

  if dc exec -T jobs bundle plugin list 2>/dev/null | grep -q bundler-multilock; then
    pass "jobs container sees bundler-multilock plugin"
  else
    fail "jobs container sees bundler-multilock plugin"
  fi

  # One Rails boot for the cache check and the job enqueue
  local out job_id
  out="$(rails_runner '
    Rails.cache.write("starwithme-smoke", "ok")
    puts "CACHE=#{Rails.cache.class.name}:#{Rails.cache.read("starwithme-smoke")}"
    Rails.cache.delete("starwithme-smoke")
    job = Delayed::Job.enqueue(Delayed::PerformableMethod.new(Kernel, :sleep, args: [0]))
    puts "JOB=#{job.id}"
  ')"

  if grep -q '^CACHE=ActiveSupport::Cache::RedisCacheStore:ok' <<<"$out"; then
    pass "Rails cache is Redis and round-trips"
  else
    fail "Rails cache is Redis and round-trips" "$(grep '^CACHE=' <<<"$out")"
  fi

  job_id="$(sed -n 's/^JOB=\([0-9]*\).*/\1/p' <<<"$out")"
  if [ -z "$job_id" ]; then
    fail "jobs worker completes an enqueued job" "could not enqueue a job"
    return
  fi

  # Capture logs before grepping: grep -q exiting early would SIGPIPE docker under pipefail
  local waited=0 logs=""
  while :; do
    logs="$(dc logs --no-log-prefix jobs 2>/dev/null)"
    grep -q "Completed .*(id=$job_id)" <<<"$logs" && break
    [ "$waited" -ge "$JOB_TIMEOUT" ] && break
    sleep 2; waited=$((waited + 2))
  done
  if grep -q "Completed .*(id=$job_id)" <<<"$logs"; then
    pass "jobs worker completes an enqueued job (id=$job_id, ${waited}s)"
  else
    fail "jobs worker completes an enqueued job" "job $job_id not completed within ${JOB_TIMEOUT}s"
  fi
}

case "${1:-all}" in
  static) static_tests ;;
  image) image_tests ;;
  runtime) runtime_tests ;;
  all) static_tests; image_tests; runtime_tests ;;
  *) echo "usage: $0 [static|image|runtime|all]"; exit 2 ;;
esac

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
