#!/usr/bin/env bash
# Staging proof from your Mac, in one line (SWM-38, SWM-201):
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/montanizstills/starWithMe/dev/infra/oci/staging-proof.sh) <VM public IP> [ref]
#
# 1. Over SSH, runs `staging.sh smoke` on the VM (image and runtime smoke
#    tests, including the error-page check).
# 2. From this machine, which is outside the tailnet's private addresses,
#    probes the VM's public IP: only 22 may answer.
# The public IP is masked in the output, so it can be pasted into Jira as is.
# SSH key: ~/.ssh/swm_oracle (override with SSH_KEY=...).
set -uo pipefail

ip=${1:-}; ref=${2:-dev}
[[ "$ip" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || { echo "Usage: staging-proof.sh <VM public IPv4> [ref]" >&2; exit 2; }
[[ "$ref" =~ ^[A-Za-z0-9._/-]+$ ]] || { echo "Unsafe ref: $ref" >&2; exit 2; }
key=${SSH_KEY:-$HOME/.ssh/swm_oracle}
mask() { sed "s/${ip//./\\.}/<public IP>/g"; }
url="https://raw.githubusercontent.com/montanizstills/starWithMe/$ref/infra/oci/staging.sh"

echo "== Staging proof, $(date -u +%FT%TZ), ref $ref"
echo
echo "== 1. Smoke tests on the VM (staging.sh smoke)"
ssh -i "$key" -o ConnectTimeout=15 "ubuntu@$ip" "bash -c 'bash <(curl -fsSL $url) smoke $ref'" 2>&1 | mask
smoke=${PIPESTATUS[0]}

echo
echo "== 2. Outside port check from $(uname -s) (expect only 22 open)"
ports_ok=1
for port in 22 80 111 443 3000 5432 6379; do
  if nc -z -w 5 "$ip" "$port" >/dev/null 2>&1; then state=open; else state=closed; fi
  echo "  $port $state"
  if [ "$port" != 22 ] && [ "$state" = open ]; then ports_ok=0; fi
done

echo
if [ "$smoke" = 0 ] && [ "$ports_ok" = 1 ]; then
  echo "== ALL PASSED"
else
  echo "== FAILED (smoke exit $smoke, ports ok: $ports_ok)"
  exit 1
fi
