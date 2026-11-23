#!/usr/bin/env bash
# Smoke tests for the Local epic: checks every committed feature of the
# containerized Canvas stack. Run from anywhere; needs the stack up for the
# runtime section (./start.sh --local, or docker compose up -d).
#
#   tests/local/smoke.sh            # all sections
#   tests/local/smoke.sh static     # repo + compose only, no containers needed
#   tests/local/smoke.sh image      # built image only (CANVAS_IMAGE, or the local build)
#   tests/local/smoke.sh runtime    # running stack only

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 2

JOB_TIMEOUT="${JOB_TIMEOUT:-60}"
CANVAS_URL="${CANVAS_URL:-http://localhost:3000}"
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

  # Staging override (SWM-222): only web publishes, and only on WEB_BIND (never 0.0.0.0)
  local cloud
  cloud="$(dc -f docker-compose.yml -f docker-compose.cloud.yml config --format json 2>/dev/null)"
  if [ "$(jq -c '[.services[] | .ports[]? | .host_ip // "0.0.0.0"]' <<<"$cloud")" = '["127.0.0.1"]' ]; then
    pass "cloud override publishes only web, on 127.0.0.1 by default"
  else
    fail "cloud override publishes only web, on 127.0.0.1 by default" "$(jq -c '[.services | to_entries[] | {(.key): [.value.ports[]? | .host_ip // "0.0.0.0"]}]' <<<"$cloud")"
  fi
  if [ "$(jq -r '[.services.web, .services.jobs | .environment.SHOW_PRODUCTION_ERRORS] | join(",")' <<<"$cloud")" = "true,true" ]; then
    pass "cloud override hides error details (SHOW_PRODUCTION_ERRORS)"
  else
    fail "cloud override hides error details (SHOW_PRODUCTION_ERRORS)"
  fi

  # Prebuilt image (SWM-229): Canvas is compiled at build time, never at start
  check "image compiles Canvas assets at build time" grep -q 'rails canvas:compile_assets' Dockerfile
  check "entrypoint never compiles or installs" sh -c "! grep -Eq 'compile_assets|bundle install|yarn install' entrypoint.sh"
  check "Dockerfile pins Canvas to a full commit SHA" grep -Eq '^ARG CANVAS_REF=[0-9a-f]{40}$' Dockerfile
  check "entrypoint uses a first-run DB flag" grep -q '/data/.db_setup_complete' entrypoint.sh
  check "compose keeps no Canvas code volume" sh -c "! grep -q canvas-src docker-compose.yml"
  if [ "$(jq -c '[.services.web.build, .services.jobs.build]' <<<"$cloud")" = '[null,null]' ]; then
    pass "cloud override pulls the image and never builds"
  else
    fail "cloud override pulls the image and never builds"
  fi

  check ".env is gitignored" git check-ignore -q .env
  check "start.sh --local adds the example course in the background" grep -q '^ *tools/apply-example-course.sh &$' start.sh
  check ".dockerignore keeps .env and .git out of builds" \
    sh -c "grep -qx '.env\*' .dockerignore && grep -qx '!.env.example' .dockerignore && grep -qx '.git' .dockerignore"
  check ".env.example has no secret values" sh -c "! grep -Eq '^(POSTGRES_PASSWORD|CANVAS_ADMIN_PASSWORD)=.+' .env.example"
  check "compose takes passwords only from env" sh -c "! grep -Eq '(POSTGRES_PASSWORD|ADMIN_PASSWORD): [^\$]' docker-compose.yml"
  check "database.yml password comes from env" grep -q 'password: <%= ENV.fetch("DB_PASSWORD") %>' Dockerfile
  check "start.sh offers --status" grep -q -- '--status)' start.sh
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

  section "Image: prebuilt Canvas (SWM-229)"

  local pinned rev
  pinned="$(sed -n 's/^ARG CANVAS_REF=//p' Dockerfile)"
  rev="$(in_image cat REVISION 2>/dev/null | tr -d '\r')"
  if [ -n "$pinned" ] && [ "$rev" = "$pinned" ]; then
    pass "image holds the pinned Canvas commit (${pinned:0:7})"
  else
    fail "image holds the pinned Canvas commit" "Dockerfile ${pinned:-none}, image ${rev:-none}"
  fi
  check "gems are installed in the image" in_image bundle check
  check "compiled assets are in the image" in_image sh -c 'ls public/dist/webpack-dev/*.js >/dev/null'
  check "node modules were left out of the image" in_image sh -c '! find /canvas -name node_modules -type d -print -quit | grep -q .'

  # No secrets baked in: no .env files, and no credential-looking variables
  local found
  found="$(in_image sh -c 'find / -xdev \( -name .env -o -name "*.env" -o -name .env.local \) -not -path "/proc/*" 2>/dev/null' | tr -d '\r')"
  if [ -z "$found" ]; then pass "no .env files in the image"; else fail "no .env files in the image" "$found"; fi
  local image
  image="$(dc config --images 2>/dev/null | grep -m1 canvas)"
  found="$(docker image inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$image" 2>/dev/null \
    | grep -iE 'password|secret|token|_key=' || true)"
  if [ -z "$found" ]; then pass "no credentials in the image's environment"; else fail "no credentials in the image's environment" "$found"; fi
  # The build's DB_PASSWORD placeholder is set inline in the build stage only
  if docker image inspect "$image" >/dev/null 2>&1 \
    && ! { docker image inspect "$image"; docker history --no-trunc "$image"; } 2>/dev/null | grep -q DB_PASSWORD; then
    pass "DB_PASSWORD is not in the image's config or history"
  else
    fail "DB_PASSWORD is not in the image's config or history"
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

  local db_port
  db_port="$(dc port db 5432 2>/dev/null)"
  if [[ "$db_port" == 127.0.0.1:* ]] && nc -z 127.0.0.1 "${db_port##*:}" 2>/dev/null; then
    pass "db reachable from host on localhost only ($db_port)"
  else
    fail "db reachable from host on localhost only" "got: ${db_port:-not published}"
  fi

  local pinned rev
  pinned="$(sed -n 's/^ARG CANVAS_REF=//p' Dockerfile)"
  rev="$(dc exec -T web cat /data/.migrated_ref 2>/dev/null | tr -d '\r')"
  if [ -n "$pinned" ] && [ "$rev" = "$pinned" ]; then
    pass "database is set up for the pinned Canvas commit (${pinned:0:7})"
  else
    fail "database is set up for the pinned Canvas commit" "pinned ${pinned:-none}, got ${rev:-none}"
  fi

  check "first-run DB setup flag present" dc exec -T web test -f /data/.db_setup_complete
  check "redis.yml points at the redis service" dc exec -T web grep -q 'redis://redis:6379' config/redis.yml
  for svc in web jobs; do
    check "$svc stores uploads on their own volume" dc exec -T "$svc" sh -c "awk '\$5 == \"/canvas/tmp/files\"' /proc/self/mountinfo | grep -q ."
  done

  local code
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 30 "$CANVAS_URL/login/canvas")"
  if [ "$code" = 200 ]; then pass "web serves /login/canvas (200)"; else fail "web serves /login/canvas (200)" "got HTTP $code"; fi

  local status_out
  status_out="$(STATUS_LOG="$(mktemp)" tests/local/status.sh 2>&1)"
  if [ $? -eq 0 ] && grep -q '^Overall: OK' <<<"$status_out"; then
    pass "./start.sh --status reports OK"
  else
    fail "./start.sh --status reports OK" "$(grep '^Overall:' <<<"$status_out")"
  fi

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
