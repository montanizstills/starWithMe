#!/usr/bin/env bash
# Step 7 of SWM-202: put the repo on the staging VM and write its .env.
# Run ON the VM as the ubuntu user, after bootstrap-vm.sh and the GHCR login:
#   bash <(curl -fsSL <raw URL of this file>)
# Clones the repo to ~/starWithMe if it isn't there, then writes .env with new
# random passwords. Nothing secret is printed; at the end it shows only the
# variable names. Safe to re-run: an existing .env is never overwritten.
set -euo pipefail

REPO_URL=https://github.com/montanizstills/starWithMe.git
DIR="$HOME/starWithMe"

# A half-finished clone (for example after Ctrl-C) is removed and started again
if [ -d "$DIR" ] && ! git -C "$DIR" rev-parse --verify -q HEAD >/dev/null; then
  echo "== Removing an incomplete clone in $DIR"
  rm -rf "$DIR"
fi
if [ ! -d "$DIR" ]; then
  # The full history is about 2 GB. A blobless clone fetches only the files
  # the checked-out branch needs (tens of MB) and still lets deploy-staging
  # check out any branch, tag or commit later.
  echo "== Cloning the repo to $DIR (blobless, with progress)"
  git clone --filter=blob:none --progress "$REPO_URL" "$DIR"
fi
cd "$DIR"

if [ -f .env ]; then
  echo "== .env already exists; leaving it alone"
else
  ts_ip=$(tailscale ip -4 2>/dev/null | head -1 || true)
  [ -n "$ts_ip" ] || { echo "Tailscale has no IPv4 address yet. Run 'sudo tailscale up' first." >&2; exit 1; }

  # Read from the terminal, so this also works when the script itself comes from a pipe
  read -rp "Canvas admin email (a new login for staging): " admin_email </dev/tty
  [ -n "$admin_email" ] || { echo "An email is required." >&2; exit 1; }

  echo "== Writing .env (mode 600)"
  umask 077
  {
    echo "# Staging VM only (SWM-202). Never commit or paste these values."
    echo "POSTGRES_PASSWORD=$(openssl rand -hex 24)"
    echo "CANVAS_ADMIN_EMAIL=$admin_email"
    echo "CANVAS_ADMIN_PASSWORD=$(openssl rand -hex 24)"
    echo "WEB_BIND=$ts_ip"
  } > .env
  chmod 600 .env
fi

echo
echo "== Check (names only; paste this into the Jira card):"
stat -c '%a %n' .env
grep -v '^#' .env | cut -d= -f1
echo
echo "Admin password, when you need it on this VM: grep ADMIN_PASSWORD ~/starWithMe/.env"
