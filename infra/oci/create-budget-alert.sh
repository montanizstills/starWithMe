#!/usr/bin/env bash
# Create a $1/month budget on the whole tenancy with two email alerts. Run in OCI Cloud Shell.
# Usage: bash <(curl -fsSL <raw URL>) you@example.com
# Safe to re-run: reuses the budget if it already exists and skips alert rules that exist.
set -uo pipefail
EMAIL=${1:-${EMAIL:-}}
[ -n "$EMAIL" ] || { echo "Usage: bash <(curl -fsSL URL) you@example.com"; exit 1; }
T=${OCI_TENANCY:?Run this in OCI Cloud Shell}
NAME=swm_1_dollar

B=$(oci budgets budget list -c "$T" --all --query "data[?\"display-name\"=='$NAME'].id | [0]" --raw-output 2>/dev/null)
if [ -z "$B" ] || [ "$B" = "null" ]; then
  B=$(oci budgets budget create -c "$T" --amount 1 --reset-period MONTHLY \
    --target-type COMPARTMENT --targets "[\"$T\"]" --display-name "$NAME" \
    --query data.id --raw-output) || { echo "Budget create failed"; exit 1; }
  echo "Created budget $NAME"
else
  echo "Budget $NAME already exists"
fi

have=$(oci budgets budget alert-rule list --budget-id "$B" --all --query 'data[]."display-name"' 2>/dev/null)
add_rule() { # name type threshold
  if printf '%s' "$have" | grep -q "\"$1\""; then echo "Alert $1 already exists"; return; fi
  oci budgets budget alert-rule create --budget-id "$B" --type "$2" --threshold "$3" \
    --threshold-type PERCENTAGE --recipients "$EMAIL" --display-name "$1" >/tmp/swm-alert.err 2>&1 \
    && echo "Created alert $1" || { echo "Alert $1 failed:"; tail -5 /tmp/swm-alert.err; }
}
add_rule actual_1pct ACTUAL 1
add_rule forecast_100pct FORECAST 100

echo
oci budgets budget alert-rule list --budget-id "$B" --all \
  --query 'data[].{name:"display-name",type:type,pct:threshold,email:recipients}' --output table
