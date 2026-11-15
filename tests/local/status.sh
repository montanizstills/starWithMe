#!/usr/bin/env bash
# Print health and footprint of the local stack (./start.sh --status).
# Read-only: never changes containers, volumes or data. Feeds Cloud sizing.
# Exits 1 if any service is not running/healthy or Canvas fails its health check.
set -uo pipefail
cd "$(dirname "$0")/../.."

PROJECT=$(docker compose config --format json 2>/dev/null | jq -r .name)
DB=(docker compose exec -T db psql -U canvas -d canvas_development -tAc)
CANVAS_URL=${CANVAS_URL:-http://localhost:3000}
STATUS_LOG=${STATUS_LOG:-logs/status-failures.log}
problems=0
failures=()

section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# Record a failed check: what failed, what we saw, the service's last log lines
# and where the full log is. No guessed fixes (SWM-10, comment 10145).
fail() {
  problems=1
  local check=$1 saw=$2 svc=${3:-}
  failures+=("$check")
  printf '\n  \033[31mFAILED:\033[0m %s\n  Saw: %s\n' "$check" "$saw"
  if [ -n "$svc" ]; then
    echo "  Last log lines ($svc):"
    docker compose logs --no-log-prefix --tail 15 "$svc" 2>&1 \
      | grep -viE 'password|secret|token' | sed 's/^/     | /'
    echo "  Full log: docker compose logs $svc"
  fi
  mkdir -p "$(dirname "$STATUS_LOG")"
  printf '%s\t%s\t%s\n' "$(date -u +%FT%TZ)" "$check" "$saw" >> "$STATUS_LOG"
}

if ! docker info >/dev/null 2>&1; then
  fail "Docker" "the Docker daemon is not reachable"
  exit 1
fi

section "Services"
printf '%-8s %-10s %s\n' SERVICE STATE HEALTH
for svc in $(docker compose config --services | sort); do
  line=$(docker compose ps -a --format '{{.State}}\t{{.Health}}' "$svc" 2>/dev/null | head -1)
  state=${line%%$'\t'*}; health=${line#*$'\t'}
  [ -z "$line" ] && state=missing health=
  printf '%-8s %-10s %s\n' "$svc" "$state" "${health:--}"
  if [ "$state" != running ]; then
    fail "$svc not running" "state=$state" "$svc"
  elif [ "$health" = unhealthy ]; then
    fail "$svc unhealthy" "its healthcheck is failing" "$svc"
  fi
done
code=$(curl -s -o /dev/null -m 10 -w '%{http_code}' "$CANVAS_URL/health_check")
echo "Canvas /health_check: $code"
if [ "$code" != 200 ]; then
  fail "Canvas health check" "HTTP $code from $CANVAS_URL/health_check (000 = no answer)" web
fi

section "CPU and memory"
ids=$(docker compose ps -q)
if [ -n "$ids" ]; then
  docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}' $ids
else
  echo "(no running containers)"
fi

section "Images"
docker compose images --format json 2>/dev/null \
  | jq -r 'if type=="array" then .[] else . end | [.ContainerName, .Repository+":"+.Tag, (.Size/1e6|floor|tostring)+" MB"] | @tsv' \
  | sort -u | column -t -s $'\t'

section "Volumes"
docker system df -v --format '{{json .Volumes}}' \
  | jq -r --arg p "${PROJECT}_" '.[] | select(.Name|startswith($p)) | [.Name, .Size] | @tsv' \
  | column -t -s $'\t'

section "Postgres"
if docker compose exec -T db true 2>/dev/null; then
  echo "Database size:  $("${DB[@]}" "select pg_size_pretty(pg_database_size(current_database()))")"
  echo "Jobs queued:    $("${DB[@]}" "select count(*) from delayed_jobs")"
  echo "Jobs ready now: $("${DB[@]}" "select count(*) from delayed_jobs where run_at <= now() and locked_at is null")"
  echo "Jobs running:   $("${DB[@]}" "select count(*) from delayed_jobs where locked_at is not null")"
  echo "Failed jobs:    $("${DB[@]}" "select count(*) from failed_jobs")"
else
  echo "(db not running; see Services above)"
fi

section "Redis"
if docker compose exec -T redis true 2>/dev/null; then
  docker compose exec -T redis redis-cli info memory \
    | tr -d '\r' | awk -F: '/^used_memory_human|^used_memory_peak_human|^maxmemory_human/ {printf "%-24s %s\n", $1":", $2}'
  echo "Keys:                    $(docker compose exec -T redis redis-cli dbsize | tr -d '\r')"
else
  echo "(redis not running; see Services above)"
fi

echo
if [ "$problems" = 0 ]; then
  echo "Overall: OK"
else
  echo "Overall: ${#failures[@]} problem(s): $(IFS=,; echo "${failures[*]}" | sed 's/,/, /g')"
  echo "Logged to $STATUS_LOG"
fi
exit "$problems"
