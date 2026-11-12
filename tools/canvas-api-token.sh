#!/usr/bin/env bash
# Create a Canvas API token for the local site admin and write it to .env as
# CANVAS_API_TOKEN, without ever printing it (SWM-206). Re-running replaces the
# previous token instead of adding another. Needs the stack up (./start.sh --local).
set -euo pipefail
cd "$(dirname "$0")/.."

ENV_FILE=${ENV_FILE:-.env}
PURPOSE="starWithMe local (tools/canvas-api-token.sh)"

[ -f "$ENV_FILE" ] || { echo "No $ENV_FILE; copy .env.example first." >&2; exit 1; }

# The admin is the user created by db:initial_setup from CANVAS_LMS_ADMIN_EMAIL.
# Earlier tokens with the same purpose are deleted, so there is only ever one.
out=$(docker compose exec -T -e PURPOSE="$PURPOSE" web bundle exec rails runner '
  user = Pseudonym.active.find_by!(unique_id: ENV.fetch("CANVAS_LMS_ADMIN_EMAIL")).user
  user.access_tokens.active.where(purpose: ENV.fetch("PURPOSE")).each(&:destroy)
  token = user.access_tokens.create!(purpose: ENV.fetch("PURPOSE"))
  puts "CANVAS_API_TOKEN=#{token.full_token}"
' 2>/dev/null) || { echo "Could not create the token: is the web container running?" >&2; exit 1; }

token=$(sed -n 's/^CANVAS_API_TOKEN=//p' <<<"$out" | tail -1)
unset out
[ -n "$token" ] || { echo "Could not create the token (no token returned)." >&2; exit 1; }

# Replace the line in place, keeping .env private (mode 600).
tmp=$(mktemp "$ENV_FILE.XXXXXX")
chmod 600 "$tmp"
grep -v '^CANVAS_API_TOKEN=' "$ENV_FILE" > "$tmp" || true
printf 'CANVAS_API_TOKEN=%s\n' "$token" >> "$tmp"
mv "$tmp" "$ENV_FILE"
chmod 600 "$ENV_FILE"
unset token
echo "token written"
