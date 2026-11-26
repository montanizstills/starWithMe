#!/usr/bin/env bash
# Static checks for the staging VM scripts (quick tier, no VM needed).
# Fails if bootstrap-vm.sh stops turning rpcbind off, or if staging.sh check
# stops reporting it.
set -euo pipefail
cd "$(dirname "$0")/../.."
fail=0
need() { grep -qE "$2" "$1" || { echo "FAIL: $1 is missing: $3"; fail=1; }; }
need infra/oci/bootstrap-vm.sh 'systemctl disable --now .*rpcbind\.socket' "disable rpcbind"
need infra/oci/bootstrap-vm.sh 'systemctl mask .*rpcbind\.socket .*rpcbind\.service' "mask rpcbind"
need infra/oci/staging.sh ':111\$' "check flags port 111"
need infra/oci/bootstrap-vm.sh 'ip_nonlocal_bind = 1' "reboot-safe WEB_BIND"
[ "$fail" = 0 ] && echo "infra hardening: OK"
exit "$fail"
