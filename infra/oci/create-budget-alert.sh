#!/usr/bin/env bash
# Create a $1/month budget on the whole tenancy with two email alerts. Run in OCI Cloud Shell.
# Usage: bash <(curl -fsSL <raw URL>) you@example.com
# Safe to re-run: reuses the budget if it already exists and skips alert rules that exist.
set -uo pipefail
EMAIL=${1:-${EMAIL:-}}
[ -n "$EMAIL" ] || { echo "Usage: bash <(curl -fsSL URL) you@example.com"; exit 1; }
T=${OCI_TENANCY:?Run this in OCI Cloud Shell}
NAME=swm_1_dollar
ERR=$(mktemp)

is_ocid() { [[ "${1:-}" == ocid1.* ]]; }

B=$(oci budgets budget budget list -c "$T" --all --target-type ALL --display-name "$NAME" \
  --query 'data[0].id' --raw-output 2>"$ERR")
if ! is_ocid "$B"; then
  B=$(oci budgets budget budget create -c "$T" --amount 1 --reset-period MONTHLY \
    --target-type COMPARTMENT --targets "[\"$T\"]" --display-name "$NAME" \
    --query data.id --raw-output 2>"$ERR")
  is_ocid "$B" || { echo "Budget create failed:"; cat "$ERR"; exit 1; }
  echo "Created budget $NAME"
else
  echo "Budget $NAME already exists"
fi

have=$(oci budgets budget alert-rule list --budget-id "$B" --all --query 'data[]."display-name"' 2>/dev/null)
add_rule() { # name type threshold
  if printf '%s' "$have" | grep -q "\"$1\""; then echo "Alert $1 already exists"; return; fi
  if oci budgets budget alert-rule create --budget-id "$B" --type "$2" --threshold "$3" \
      --threshold-type PERCENTAGE --recipients "$EMAIL" --display-name "$1" >/dev/null 2>"$ERR"; then
    echo "Created alert $1"
  else
    echo "Alert $1 failed:"; cat "$ERR"
  fi
}
add_rule actual_1pct ACTUAL 1
add_rule forecast_100pct FORECAST 100

echo
oci budgets budget alert-rule list --budget-id "$B" --all \
  --query 'data[].{name:"display-name",type:type,pct:threshold,email:recipients}' --output table
rm -f "$ERR"
