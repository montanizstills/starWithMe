#!/usr/bin/env bash
# Quick-tier check for tools/rotate-admin-password.sh (SWM-228). No Canvas:
# a fake `docker` on PATH plays the running stack, keeps the admin password
# Canvas holds, and logs every command line it gets. deploy-test.yml runs the
# real thing against Canvas.
#
#   tests/local/rotate-admin-password.test.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }
t() { local name=$1; shift; if "$@"; then ok "$name"; else bad "$name"; fi; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Fake docker. State lives in $FAKE: canvas_pw (what Canvas accepts), argv.log,
# running (stack up or not), refuse (Canvas rejects the change), tokens.
mkdir -p "$work/bin"
cat > "$work/bin/docker" <<'FAKE_DOCKER'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FAKE/argv.log"
[ "$1" = compose ] || exit 1
case "$2" in
  ps) [ -f "$FAKE/running" ] && echo abc123; exit 0 ;;
  exec) ;;
  *) exit 1 ;;
esac
code="${*: -1}"
case "$code" in
  *canvas-admin-password*|*"puts \"ROTATED\""*)
    { IFS= read -r new; IFS= read -r old; } || true
    echo "Rails noise on stderr" >&2
    if [ -f "$FAKE/refuse" ]; then echo "ERROR=Canvas refused the password: Password is too short"; exit 0; fi
    [ "$old" = "$(cat "$FAKE/canvas_pw")" ] || { echo "ERROR=old password did not match"; exit 0; }
    printf '%s' "$new" > "$FAKE/canvas_pw"
    echo ROTATED
    ;;
  *TOKEN=*)
    n=$(( $(cat "$FAKE/tokens" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$FAKE/tokens"
    [ -f "$FAKE/no_token" ] && exit 1
    echo "TOKEN=fake-token-$n"
    ;;
  *) exit 1 ;;
esac
FAKE_DOCKER
chmod +x "$work/bin/docker"

# A copy of the repo's tools and start.sh, with a .env, per scenario
setup() {
  local d="$work/$1"
  mkdir -p "$d/tools" "$d/fake"
  cp "$ROOT/tools/rotate-admin-password.sh" "$ROOT/tools/canvas-admin-password.rb" "$ROOT/tools/canvas-token.rb" "$d/tools/"
  printf 'POSTGRES_PASSWORD=db-secret\nCANVAS_ADMIN_EMAIL=admin@example.test\nCANVAS_ADMIN_PASSWORD=old-default-pw\n# a comment\nCANVAS_API_TOKEN=old-token\nTEST_STUDENT_PASSWORD=student-pw' > "$d/.env"
  printf 'old-default-pw' > "$d/fake/canvas_pw"
  touch "$d/fake/running"
  echo "$d"
}
run() { (cd "$1" && PATH="$work/bin:$PATH" FAKE="$1/fake" tools/rotate-admin-password.sh > "$1/out" 2>&1); echo $? > "$1/rc"; }
envval() { sed -n "s/^$2=//p" "$1/.env"; }

echo "rotate: happy path"
d=$(setup happy); run "$d"
new=$(envval "$d" CANVAS_ADMIN_PASSWORD)
t "exits 0" [ "$(cat "$d/rc")" = 0 ]
t "prints nothing" [ ! -s "$d/out" ]
t "new password is 48 hex characters" grep -Eq '^[0-9a-f]{48}$' <<<"$new"
t "Canvas holds the password .env holds" [ "$(cat "$d/fake/canvas_pw")" = "$new" ]
t "old default password is gone from .env" bash -c "! grep -q old-default-pw '$d/.env'"
t "password never in a docker command line" bash -c "! grep -qF -- '$new' '$d/fake/argv.log' && ! grep -q old-default-pw '$d/fake/argv.log'"
t "API token remade" [ "$(envval "$d" CANVAS_API_TOKEN)" = fake-token-1 ]
t "one CANVAS_API_TOKEN line" [ "$(grep -c '^CANVAS_API_TOKEN=' "$d/.env")" = 1 ]
t "other lines kept" bash -c "grep -qx 'POSTGRES_PASSWORD=db-secret' '$d/.env' && grep -qx '# a comment' '$d/.env' && grep -qx 'TEST_STUDENT_PASSWORD=student-pw' '$d/.env' && grep -qx 'CANVAS_ADMIN_EMAIL=admin@example.test' '$d/.env'"
t ".env is private (600)" [ "$(stat -c %a "$d/.env" 2>/dev/null || stat -f %Lp "$d/.env")" = 600 ]
t "no scratch files left" bash -c "! ls '$d'/.env.rotate.* >/dev/null 2>&1"

echo "rotate: twice in a row"
run "$d"
t "second run exits 0" [ "$(cat "$d/rc")" = 0 ]
t "second run gives another password" [ "$(envval "$d" CANVAS_ADMIN_PASSWORD)" != "$new" ]
t "Canvas and .env still agree" [ "$(cat "$d/fake/canvas_pw")" = "$(envval "$d" CANVAS_ADMIN_PASSWORD)" ]

echo "rotate: Canvas refuses"
d=$(setup refuse); touch "$d/fake/refuse"; cp "$d/.env" "$d/env.before"; run "$d"
t "exits 3" [ "$(cat "$d/rc")" = 3 ]
t ".env unchanged" cmp -s "$d/.env" "$d/env.before"
t "says why without a value" bash -c "grep -q 'too short' '$d/out' && ! grep -Eq '[0-9a-f]{48}' '$d/out'"
t "no scratch files left" bash -c "! ls '$d'/.env.rotate.* >/dev/null 2>&1"

echo "rotate: Canvas not running"
d=$(setup down); rm "$d/fake/running"; cp "$d/.env" "$d/env.before"; run "$d"
t "exits 2" [ "$(cat "$d/rc")" = 2 ]
t ".env unchanged" cmp -s "$d/.env" "$d/env.before"
t "Canvas not touched" [ "$(cat "$d/fake/canvas_pw")" = old-default-pw ]

echo "rotate: token cannot be made"
d=$(setup notoken); touch "$d/fake/no_token"; run "$d"
t "exits 4" [ "$(cat "$d/rc")" = 4 ]
t "password still rotated in Canvas and .env" [ "$(cat "$d/fake/canvas_pw")" = "$(envval "$d" CANVAS_ADMIN_PASSWORD)" ]
t "stale token dropped, so start.sh makes a new one" bash -c "! grep -q '^CANVAS_API_TOKEN=' '$d/.env'"

echo "rotate: refuses the staging stack"
d=$(setup staging); printf '\nWEB_BIND=100.64.0.1\n' >> "$d/.env"; cp "$d/.env" "$d/env.before"; run "$d"
t "exits 2 with WEB_BIND in .env" [ "$(cat "$d/rc")" = 2 ]
t ".env unchanged" cmp -s "$d/.env" "$d/env.before"
t "Canvas not touched" [ "$(cat "$d/fake/canvas_pw")" = old-default-pw ]
d=$(setup cloud); (cd "$d" && PATH="$work/bin:$PATH" FAKE="$d/fake" COMPOSE_FILE=docker-compose.yml:docker-compose.cloud.yml tools/rotate-admin-password.sh >/dev/null 2>&1); rc=$?
t "exits 2 with the cloud compose file" [ "$rc" = 2 ]
t "Canvas not touched" [ "$(cat "$d/fake/canvas_pw")" = old-default-pw ]

echo "rotate: stays local only"
t "start.sh has no rotate option" bash -c "! grep -qi rotate '$ROOT/start.sh'"
t ".dockerignore keeps it out of builds" bash -c "grep -qx 'tools/rotate-admin-password.sh' '$ROOT/.dockerignore' && grep -qx 'tools/canvas-admin-password.rb' '$ROOT/.dockerignore'"

echo "rotate: canvas-admin-password.rb"
if command -v ruby >/dev/null; then
  t "ruby syntax ok" bash -c "ruby -c '$ROOT/tools/canvas-admin-password.rb' >/dev/null"
else
  echo "  skip ruby not installed"
fi

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
