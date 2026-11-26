#!/usr/bin/env bash
# Rotate the local Canvas site admin's password (SWM-228).
#
#   tools/rotate-admin-password.sh
#
# Local only, on purpose. It is not a start.sh option, it is kept out of the
# Docker build context (.dockerignore), and it refuses to run against the
# staging stack (WEB_BIND in .env or docker-compose.cloud.yml in COMPOSE_FILE).
# Staging secrets rotate through the GitHub staging environment (SWM-239).
#
# Makes a new random password, sets it on the admin in the running Canvas,
# checks that it works and the old one no longer does, then writes it to
# CANVAS_ADMIN_PASSWORD in .env. Afterwards it remakes the admin's API token
# (CANVAS_API_TOKEN in .env) the same way as SWM-206.
#
# Prints nothing when it works. The password only ever goes to .env and, over
# stdin, to Canvas: never on screen, in a command line, an environment variable
# or a log. Read it with: grep CANVAS_ADMIN_PASSWORD .env
#
# Exit codes: 0 rotated; 2 not ready (no .env, Canvas not running); 3 Canvas
# refused the change (.env untouched); 4 rotated but the token was not remade;
# 5 rotated but .env could not be written (the new password is left in the
# .env.rotate.* file it names).
#
# Runs on macOS's bash 3.2 too.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

TOKEN_PURPOSE="starWithMe local (courses)"   # same as tools/apply-example-course.sh
err() { echo "rotate-admin-password: $*" >&2; }

[ -f .env ] || { err "no .env in $(pwd); copy .env.example to .env first."; exit 2; }
if grep -q '^WEB_BIND=' .env || [[ "${COMPOSE_FILE:-}" == *cloud* ]]; then
  err "this is the staging stack; this tool is for the local Canvas only. Staging secrets rotate via SWM-239."
  exit 2
fi
grep -q '^CANVAS_ADMIN_PASSWORD=' .env || { err "CANVAS_ADMIN_PASSWORD is not in .env."; exit 2; }
command -v openssl >/dev/null || { err "openssl is not installed."; exit 2; }
if [ -z "$(docker compose ps web --status running -q 2>/dev/null)" ]; then
  err "Canvas is not running. Start it with ./start.sh --local, wait until it is up, then run this again."
  exit 2
fi

# copy_env <src> <dst> <key> <value>: src with KEY set to value (added if
# missing; an empty value drops the line). Plain bash, so the value never
# reaches a command line.
copy_env() {
  local src=$1 dst=$2 key=$3 value=$4 line seen=""
  : > "$dst" || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "$key="*)
        [ -n "$seen" ] && continue
        seen=1
        [ -n "$value" ] && printf '%s=%s\n' "$key" "$value"
        ;;
      *) printf '%s\n' "$line" ;;
    esac
  done < "$src" >> "$dst" || return 1
  if [ -z "$seen" ] && [ -n "$value" ]; then printf '%s=%s\n' "$key" "$value" >> "$dst" || return 1; fi
}

old=$(sed -n 's/^CANVAS_ADMIN_PASSWORD=//p' .env | head -1)
new=$(openssl rand -hex 24)
[ "${#new}" = 48 ] || { err "openssl did not make a password."; exit 2; }

# Write the new .env first, beside the old one (mktemp makes it 0600), so the
# swap after Canvas accepts the password is a single rename.
tmp=$(mktemp .env.rotate.XXXXXX) || { err "could not write a file next to .env."; exit 2; }
trap 'rm -f "$tmp"' EXIT
copy_env .env "$tmp" CANVAS_ADMIN_PASSWORD "$new" || { err "could not write $tmp."; exit 2; }

result=$(printf '%s\n%s\n' "$new" "$old" | docker compose exec -T web \
  bundle exec rails runner "$(cat tools/canvas-admin-password.rb)" 2>/dev/null | grep -E '^(ROTATED|ERROR=)' | tail -1)
unset old
if [ "$result" != ROTATED ]; then
  err "Canvas did not change the password, so .env is unchanged (${result#ERROR=})."
  [ -n "$result" ] || err "Is Canvas still starting? Check with ./start.sh --status."
  exit 3
fi

if ! mv -f "$tmp" .env; then
  trap - EXIT
  err "Canvas has the new password but .env could not be updated. It is in $tmp: move that file to .env now."
  exit 5
fi
trap - EXIT
unset new

# SWM-206: remake the admin's API token. canvas-token.rb replaces the token with
# this purpose, so the old one stops working.
token=$(docker compose exec -T -e TOKEN_PURPOSE="$TOKEN_PURPOSE" web \
  bundle exec rails runner "$(cat tools/canvas-token.rb)" 2>/dev/null | sed -n 's/^TOKEN=//p' | tail -1)
tmp=$(mktemp .env.rotate.XXXXXX) || { err "Password rotated, but could not write a file next to .env for the token."; exit 4; }
trap 'rm -f "$tmp"' EXIT
# No token: drop the old line, and tools/apply-example-course.sh makes a new one
copy_env .env "$tmp" CANVAS_API_TOKEN "$token" && mv -f "$tmp" .env || {
  err "Password rotated, but CANVAS_API_TOKEN in .env could not be updated."; exit 4; }
trap - EXIT
if [ -z "$token" ]; then
  err "Password rotated, but the API token was not remade. ./start.sh --local makes one (or run tools/apply-example-course.sh)."
  exit 4
fi
exit 0
