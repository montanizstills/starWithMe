#!/usr/bin/env bash
# Step 8 of SWM-202: fill the GitHub environment `staging` used by
# deploy-staging (and later inject-course / student-test-staging).
# Run on your Mac (not the VM), with the gh CLI signed in:
#   bash <(curl -fsSL <raw URL of this file>) ubuntu@<VM public IP>
# Optional: SSH_KEY=~/.ssh/other-key to pick the key you use to reach the VM.
#
# It sets these secrets, never printing a value:
#   STAGING_HOST          the VM's Tailscale IPv4, read from the VM over SSH
#   STAGING_SSH_KEY       a new key made only for CI; its public half is added to the VM
#   TEST_STUDENT_PASSWORD a new random password
#   TS_OAUTH_CLIENT_ID    you paste it at gh's hidden prompt
#   TS_OAUTH_SECRET       you paste it at gh's hidden prompt
# Secrets that already exist are skipped. Works with macOS's bash 3.2.
set -euo pipefail

REPO=montanizstills/starWithMe
ENV=staging
TARGET=${1:-}
[ -n "$TARGET" ] || { echo "Usage: ... ubuntu@<VM public IP>" >&2; exit 1; }

SSH_KEY=${SSH_KEY:-$HOME/.ssh/swm-oracle}
SSH_OPTS=(-o ConnectTimeout=15)
[ -f "$SSH_KEY" ] && SSH_OPTS+=(-i "$SSH_KEY")

command -v gh >/dev/null || { echo "Install the GitHub CLI first: brew install gh" >&2; exit 1; }
gh auth status -h github.com >/dev/null 2>&1 || { echo "Sign in first: gh auth login" >&2; exit 1; }

echo "== Making sure the environment '$ENV' exists"
gh api -X PUT "repos/$REPO/environments/$ENV" >/dev/null

existing=$(gh secret list -R "$REPO" --env "$ENV" --json name -q '.[].name' 2>/dev/null || true)
has() { printf '%s\n' "$existing" | grep -qx "$1"; }

if has STAGING_HOST; then echo "-- STAGING_HOST already set"; else
  echo "== STAGING_HOST: asking the VM for its Tailscale IP"
  ts_ip=$(ssh "${SSH_OPTS[@]}" "$TARGET" 'tailscale ip -4 | head -1')
  [ -n "$ts_ip" ] || { echo "The VM has no Tailscale IP yet." >&2; exit 1; }
  printf '%s' "$ts_ip" | gh secret set STAGING_HOST -R "$REPO" --env "$ENV"
fi

if has STAGING_SSH_KEY; then echo "-- STAGING_SSH_KEY already set"; else
  ci_key="$HOME/.ssh/swm-staging-ci"
  if [ ! -f "$ci_key" ]; then
    echo "== Making a CI-only SSH key at $ci_key"
    ssh-keygen -q -t ed25519 -N '' -C 'swm-staging-ci (GitHub Actions)' -f "$ci_key"
  fi
  echo "== Adding its public half to the VM's authorized_keys"
  ssh "${SSH_OPTS[@]}" "$TARGET" 'umask 077; mkdir -p ~/.ssh; k=$(cat); grep -qxF "$k" ~/.ssh/authorized_keys 2>/dev/null || echo "$k" >> ~/.ssh/authorized_keys' < "$ci_key.pub"
  gh secret set STAGING_SSH_KEY -R "$REPO" --env "$ENV" < "$ci_key"
fi

if has TEST_STUDENT_PASSWORD; then echo "-- TEST_STUDENT_PASSWORD already set"; else
  echo "== TEST_STUDENT_PASSWORD: new random value"
  openssl rand -hex 16 | tr -d '\n' | gh secret set TEST_STUDENT_PASSWORD -R "$REPO" --env "$ENV"
fi

for name in TS_OAUTH_CLIENT_ID TS_OAUTH_SECRET; do
  if has "$name"; then echo "-- $name already set"; else
    echo "== $name: paste it from the Tailscale admin console (input is hidden)"
    gh secret set "$name" -R "$REPO" --env "$ENV"
  fi
done

echo
echo "== Secrets in '$ENV' (names only; paste this into the Jira card):"
gh secret list -R "$REPO" --env "$ENV"
