#!/usr/bin/env bash
# Wait for Canvas, then add the example course with `courses apply` (SWM-207).
# ./start.sh --local runs this beside `docker compose up`. It never stops the
# stack from starting: any problem is reported and the stack keeps running.
# The interface of `courses apply` is defined on SWM-205.
set -uo pipefail
cd "$(dirname "$0")/.."

COURSE_DIR=courses/example-playwright-browser-use
CANVAS_URL=${CANVAS_URL:-http://localhost:3000}
APPLY="tools/courses/courses apply $COURSE_DIR --target local"
say() { echo "[courses] $*"; }

# First-run setup can take an hour, so wait as long as it takes
until [ "$(curl -s -o /dev/null -m 5 -w '%{http_code}' "$CANVAS_URL/health_check")" = 200 ]; do
  sleep 15
done

if [ ! -x tools/courses/courses ] || [ ! -d "$COURSE_DIR" ]; then
  say "courses apply or $COURSE_DIR is not here yet; skipping the example course."
  exit 0
fi

if [ -z "${CANVAS_API_TOKEN:-}" ] && ! grep -q '^CANVAS_API_TOKEN=.' .env 2>/dev/null; then
  say "No CANVAS_API_TOKEN, so the example course was not added. To add it:"
  say "  tools/canvas-api-token.sh && $APPLY"
  exit 0
fi

# stdout is one JSON report; progress on stderr is shown with a prefix
report=$($APPLY 2> >(sed 's/^/[courses] /' >&2))
rc=$?
case $rc in
  0) say "Example course applied: $(jq '.changes | length' <<<"$report" 2>/dev/null || echo '?') change(s)." ;;
  1) say "courses apply failed: the course files did not validate (exit 1)." ;;
  2) say "courses apply failed: config, auth or Canvas unreachable (exit 2)." ;;
  3) say "courses apply failed: Canvas returned an error (exit 3); re-running is safe." ;;
  *) say "courses apply failed (exit $rc)." ;;
esac
[ "$rc" = 0 ] || say "The stack is still running. Re-run with: $APPLY"
exit 0
