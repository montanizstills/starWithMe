#!/usr/bin/env bash
# Manual staging runbook, run ON the staging VM (SWM-222, SWM-223, SWM-225).
# The same steps as the deploy-staging, inject-course and student-test-staging
# workflows, for as long as those can't be started from GitHub (the repo's
# default branch is prod). One line each:
#
#   bash <(curl -fsSL <raw URL>) deploy  [ref] [image_tag]   default: dev latest
#   bash <(curl -fsSL <raw URL>) inject  [ref] [course]      default: dev courses/example-playwright-browser-use
#   bash <(curl -fsSL <raw URL>) student [ref]               default: dev
#   bash <(curl -fsSL <raw URL>) status
#   bash <(curl -fsSL <raw URL>) check                    proof for SWM-202 / SWM-36, no secrets
#   bash <(curl -fsSL <raw URL>) smoke   [ref]               smoke tests on this stack (SWM-38, SWM-201)
#
# Works in ~/starWithMe (setup-staging-env.sh creates it). Never prints a secret.
# The test student's password lives in the VM's .env as TEST_STUDENT_PASSWORD;
# the first inject adds it if it's missing.
set -euo pipefail

DIR="$HOME/starWithMe"
COMPOSE=(docker compose -f docker-compose.yml -f docker-compose.cloud.yml)
TOKEN_PURPOSE="starWithMe staging (manual inject)"

cd "$DIR" 2>/dev/null || { echo "No $DIR. Run setup-staging-env.sh first." >&2; exit 1; }
[ -f .env ] || { echo "No .env in $DIR. Run setup-staging-env.sh first." >&2; exit 1; }

env_get() { sed -n "s/^$1=//p" .env | tail -1; }
WEB_BIND=$(env_get WEB_BIND); WEB_BIND=${WEB_BIND:-127.0.0.1}
CANVAS_URL="http://$WEB_BIND:3000"

checkout() {
  local ref=$1
  [[ "$ref" =~ ^[A-Za-z0-9._/-]+$ ]] || { echo "Unsafe ref: $ref" >&2; exit 1; }
  git fetch -q --prune --tags origin
  local sha
  sha=$(git rev-parse --verify -q "origin/$ref^{commit}" || git rev-parse --verify "$ref^{commit}")
  git checkout -q --detach "$sha"
  echo "== Code at $ref ($(git rev-parse --short HEAD))"
}

healthy() { [ "$(curl -s -o /dev/null -m 10 -w '%{http_code}' "$CANVAS_URL/health_check" || true)" = 200 ]; }

need_canvas() { healthy || { echo "Canvas isn't healthy at $CANVAS_URL. Run: ... deploy" >&2; exit 1; }; }

need_python() {
  python3 -c 'import sys; sys.exit(sys.version_info < (3, 11))' || { echo "Needs Python 3.11+" >&2; exit 1; }
  python3 -c 'import ensurepip' 2>/dev/null || { echo "== Installing python3-venv"; sudo apt-get install -y -qq python3-venv >/dev/null; }
}

cmd=${1:-help}; shift || true
case "$cmd" in
  deploy)
    ref=${1:-dev}; tag=${2:-latest}
    [[ "$tag" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "Unsafe image tag: $tag" >&2; exit 1; }
    checkout "$ref"
    export CANVAS_IMAGE="ghcr.io/montanizstills/starwithme-canvas:$tag"
    echo "== Pulling $CANVAS_IMAGE"
    "${COMPOSE[@]}" pull web
    echo "== Starting the stack"
    "${COMPOSE[@]}" up -d --remove-orphans
    "${COMPOSE[@]}" ps
    echo "== Waiting for $CANVAS_URL/health_check (up to 30 min; first run sets up the database)"
    start=$(date +%s)
    for i in $(seq 1 60); do
      if healthy; then echo "== Canvas is up (HTTP 200 after $(( ($(date +%s) - start) / 60 )) min)"; exit 0; fi
      [ $((i % 6)) = 0 ] && "${COMPOSE[@]}" logs --no-log-prefix --tail 3 web 2>&1 | grep -viE 'password|secret|token' | sed 's/^/  web | /' || true
      sleep 30
    done
    echo "Canvas isn't up after 30 min. The stack keeps running; re-run 'status' later." >&2; exit 1
    ;;

  inject)
    ref=${1:-dev}; course=${2:-courses/example-playwright-browser-use}
    [[ "$course" =~ ^courses/[A-Za-z0-9._-]+$ ]] || { echo "Course must be a folder under courses/" >&2; exit 1; }
    checkout "$ref"
    [ -x tools/courses/courses ] || { echo "The courses tool isn't on $ref yet (PR #11)." >&2; exit 1; }
    [ -d "$course" ] || { echo "$course isn't on $ref yet (PR #9)." >&2; exit 1; }
    need_canvas; need_python
    if [ -z "$(env_get TEST_STUDENT_PASSWORD)" ]; then
      echo "== Adding TEST_STUDENT_PASSWORD to .env (new random value)"
      printf 'TEST_STUDENT_PASSWORD=%s\n' "$(openssl rand -hex 16)" >> .env
    fi
    [ -f tools/canvas-token.rb ] || { echo "tools/canvas-token.rb isn't on $ref yet (PR #11)." >&2; exit 1; }
    echo "== Enabling SIS imports and making an API token (not shown)"
    token=$("${COMPOSE[@]}" exec -T -e TOKEN_PURPOSE="$TOKEN_PURPOSE" web \
      bundle exec rails runner "$(cat tools/canvas-token.rb)" 2>"$HOME/.canvas-token.err" | sed -n 's/^TOKEN=//p' | tail -1 || true)
    [ -n "$token" ] || { echo "Could not create a token in the web container:" >&2; grep -v '^[[:space:]]*from ' "$HOME/.canvas-token.err" | head -20 >&2; exit 1; }
    cleanup() {
      "${COMPOSE[@]}" exec -T -e PURPOSE="$TOKEN_PURPOSE" web bundle exec rails runner \
        'AccessToken.active.where(purpose: ENV.fetch("PURPOSE")).each(&:destroy)' >/dev/null 2>&1 || true
    }
    trap cleanup EXIT
    export CANVAS_URL CANVAS_API_TOKEN="$token" TEST_STUDENT_PASSWORD
    TEST_STUDENT_PASSWORD=$(env_get TEST_STUDENT_PASSWORD)
    unset token
    mkdir -p "$HOME/staging-reports"
    report="$HOME/staging-reports/apply-$(date -u +%Y%m%dT%H%M%SZ).json"
    echo "== Applying $course"
    tools/courses/courses apply "$course" --target staging > "$report"
    python3 -c 'import json,sys; r=json.load(open(sys.argv[1])); print("summary:", json.dumps(r["summary"])); print("changes:", len(r["changes"]))' "$report"
    echo "== Applying again (must be 0 changes)"
    tools/courses/courses apply "$course" --target staging > "$report.rerun"
    python3 -c 'import json,sys; r=json.load(open(sys.argv[1])); print("summary:", json.dumps(r["summary"])); sys.exit(1 if r["changes"] else 0)' "$report.rerun" \
      && echo "== OK: second apply made 0 changes. Reports: $report{,.rerun}"
    ;;

  student)
    ref=${1:-dev}
    checkout "$ref"
    [ -x tests/e2e/run.sh ] || { echo "The student test isn't on $ref yet (PR #6)." >&2; exit 1; }
    need_canvas; need_python
    TEST_STUDENT_PASSWORD=$(env_get TEST_STUDENT_PASSWORD)
    [ -n "$TEST_STUDENT_PASSWORD" ] || { echo "No TEST_STUDENT_PASSWORD in .env. Run inject first." >&2; exit 1; }
    export CANVAS_URL TEST_STUDENT_PASSWORD
    echo "== Running the student test against $CANVAS_URL (first run installs Chromium)"
    PLAYWRIGHT_DEPS=1 tests/e2e/run.sh && echo "== PASSED. Report: $DIR/tests/e2e/test-results/junit.xml"
    ;;

  smoke)
    # SWM-38: the image and runtime smoke sections against this VM's stack,
    # over the Tailscale address. Includes the SWM-201 error-page check.
    ref=${1:-dev}
    checkout "$ref"
    need_canvas
    export CANVAS_URL SMOKE_TARGET=staging
    rc=0
    tests/local/smoke.sh image || rc=1
    tests/local/smoke.sh runtime || rc=1
    if [ "$rc" = 0 ]; then echo "== SMOKE PASSED at $(git rev-parse --short HEAD)"; else echo "== SMOKE FAILED at $(git rev-parse --short HEAD)"; fi
    exit "$rc"
    ;;

  status)
    echo "== $(git rev-parse --short HEAD 2>/dev/null) checked out"
    "${COMPOSE[@]}" ps
    healthy && echo "== Canvas healthy at $CANVAS_URL" || echo "== Canvas not healthy at $CANVAS_URL"
    free -h | grep -E 'Mem|Swap'
    ;;

  check)
    # Proof for SWM-202 / SWM-36. Prints no secrets and no public IP.
    echo "== Oracle metadata (region, shape)"
    curl -s -m 5 -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/ | grep -E '"(canonicalRegionName|shape)"' || echo "  (metadata service not reachable)"
    echo "== CPU, memory, swap, disk"
    nproc; free -h | grep -E 'Mem|Swap'; df -h / | tail -1
    echo "== OS, Docker, Tailscale"
    lsb_release -ds; uname -m; docker --version
    tailscale status --self --peers=false | awk '{print $2, $4, $5}'
    echo "== GHCR login present (1 = yes)"
    grep -c ghcr.io ~/.docker/config.json || true
    echo "== .env (names only)"
    stat -c '%a %n' "$DIR/.env"; grep -v '^#' "$DIR/.env" | cut -d= -f1
    echo "== .env tracked by git? (expect nothing)"
    git ls-files --error-unmatch .env 2>/dev/null || echo "  not tracked"
    echo "== Containers"
    "${COMPOSE[@]}" ps --format 'table {{.Service}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
    echo "== /health_check over Tailscale"
    curl -s -o /dev/null -m 10 -w '  HTTP %{http_code}\n' "$CANVAS_URL/health_check" || true
    echo "== Error page leaks a stack trace? (expect 0)"
    curl -s -m 15 "$CANVAS_URL/no-such-page-swm" | grep -ciE 'backtrace|stack trace|\.rb:[0-9]' || true
    echo "== Ports listening on all interfaces (expect only 22, and Tailscale's own)"
    sudo ss -ltnH | awk '{print $4}' | grep -E '^(0\.0\.0\.0|\*|\[::\]):' | sort -u
    echo "== rpcbind (expect masked, and nothing on port 111)"
    echo "  $(systemctl is-enabled rpcbind.socket 2>/dev/null || echo not-installed)"
    if sudo ss -ltnH | awk '{print $4}' | grep -qE ':111$'; then
      echo "  WARNING: port 111 is listening. Re-run bootstrap-vm.sh to turn rpcbind off."
    fi
    ;;

  *)
    echo "Usage: staging.sh deploy [ref] [image_tag] | inject [ref] [course] | student [ref] | smoke [ref] | status | check"
    ;;
esac
