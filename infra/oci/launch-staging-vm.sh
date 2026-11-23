#!/usr/bin/env bash
# Launch the StarWithMe staging VM (SWM-36 / SWM-202) from OCI Cloud Shell.
#
# Why this exists: Oracle's AI assistant adds instance_options.areLegacyImdsEndpointsDisabled,
# which its own validator rejects. This uses the plain OCI CLI, which Cloud Shell has
# preinstalled and already signed in, so no keys or tokens are needed here.
#
# Free A1 capacity in us-chicago-1 is often full ("Out of host capacity"). The script tries
# every availability domain, waits, and tries again until a VM is created.
# It is safe to re-run: it stops if a non-terminated VM with the same name already exists.
#
# Usage (in Cloud Shell):
#   1. Put your PUBLIC key in ~/swm-oracle.pub  (cat > ~/swm-oracle.pub, paste, Ctrl-D)
#   2. bash <(curl -fsSL <raw URL of this file>)
#
# Optional overrides: COMPARTMENT_OCID, SUBNET_ID, SUBNET_NAME, SSH_KEY_FILE, NAME, WAIT_SECONDS

set -uo pipefail

NAME=${NAME:-swm-staging}
SHAPE=VM.Standard.A1.Flex
OCPUS=1
MEM_GB=6
BOOT_GB=100
C=${COMPARTMENT_OCID:-${OCI_TENANCY:-}}
SUBNET_NAME=${SUBNET_NAME:-swm-subnet-20261115-2230}
SSH_KEY_FILE=${SSH_KEY_FILE:-$HOME/swm-oracle.pub}
WAIT_SECONDS=${WAIT_SECONDS:-60}

die() { echo "ERROR: $*" >&2; exit 1; }

command -v oci >/dev/null || die "oci CLI not found. Run this in OCI Cloud Shell."
[ -n "$C" ] || die "No compartment. Set COMPARTMENT_OCID."
[ -s "$SSH_KEY_FILE" ] || die "Put your SSH PUBLIC key (one line, starts with ssh-ed25519) in $SSH_KEY_FILE"
grep -q '^ssh-' "$SSH_KEY_FILE" || die "$SSH_KEY_FILE does not look like a public key"
grep -q 'PRIVATE KEY' "$SSH_KEY_FILE" && die "That is a PRIVATE key. Use the .pub file."

echo "Checking for an existing $NAME ..."
existing=$(oci compute instance list -c "$C" --display-name "$NAME" --all \
  --query 'data[?"lifecycle-state"!=`"TERMINATED"`].id | [0]' --raw-output 2>/dev/null || true)
if [ -n "$existing" ] && [ "$existing" != "null" ]; then
  echo "A VM named $NAME already exists: $existing"
  echo "Nothing to do."
  exit 0
fi

SUBNET=${SUBNET_ID:-$(oci network subnet list -c "$C" --display-name "$SUBNET_NAME" --all \
  --query 'data[0].id' --raw-output 2>/dev/null || true)}
if [ -z "$SUBNET" ] || [ "$SUBNET" = "null" ]; then
  echo "Subnet $SUBNET_NAME not found. Subnets in this compartment:"
  oci network subnet list -c "$C" --all --query 'data[].{name:"display-name",id:id}' --output table
  die "Re-run with SUBNET_ID=<id from the table>"
fi
echo "Subnet: $SUBNET_NAME"

IMG=$(oci compute image list -c "$C" --operating-system "Canonical Ubuntu" \
  --operating-system-version "24.04" --shape "$SHAPE" \
  --sort-by TIMECREATED --sort-order DESC --query 'data[0].id' --raw-output 2>/dev/null || true)
[ -n "$IMG" ] && [ "$IMG" != "null" ] || die "No Ubuntu 24.04 aarch64 image found for $SHAPE"
echo "Image: $(oci compute image get --image-id "$IMG" --query 'data."display-name"' --raw-output)"

mapfile -t ADS < <(oci iam availability-domain list -c "$C" --query 'data[].name' | jq -r '.[]')
[ ${#ADS[@]} -gt 0 ] || die "No availability domains found"
echo "Availability domains: ${ADS[*]}"
echo

attempt=0
while true; do
  attempt=$((attempt + 1))
  for AD in "${ADS[@]}"; do
    echo "[$(date +%H:%M:%S)] attempt $attempt, $AD ..."
    out=$(oci compute instance launch -c "$C" \
      --availability-domain "$AD" \
      --display-name "$NAME" \
      --shape "$SHAPE" \
      --shape-config "{\"ocpus\": $OCPUS, \"memoryInGBs\": $MEM_GB}" \
      --image-id "$IMG" \
      --subnet-id "$SUBNET" \
      --assign-public-ip true \
      --boot-volume-size-in-gbs "$BOOT_GB" \
      --ssh-authorized-keys-file "$SSH_KEY_FILE" \
      --wait-for-state RUNNING --max-wait-seconds 900 2>&1)
    rc=$?
    if [ $rc -eq 0 ]; then
      id=$(printf '%s\n' "$out" | sed -n '/^{/,$p' | jq -r '.data.id' 2>/dev/null)
      echo
      echo "VM created and RUNNING in $AD."
      [ -n "$id" ] && [ "$id" != "null" ] && \
        echo "Public IP: $(oci compute instance list-vnics --instance-id "$id" --query 'data[0]."public-ip"' --raw-output)"
      echo "SSH: ssh -i ~/.ssh/swm-oracle ubuntu@<public IP>"
      exit 0
    fi
    if printf '%s' "$out" | grep -qiE 'out of (host )?capacity|InternalError|TooManyRequests'; then
      echo "  no capacity there yet"
      sleep 5
      continue
    fi
    if printf '%s' "$out" | grep -qi 'LimitExceeded'; then
      echo "$out"
      die "Free-tier limit reached: another A1 VM or boot volume is already using it. Check Compute > Instances and Block Storage."
    fi
    echo "$out"
    die "Launch failed for a reason other than capacity (above)."
  done
  echo "All ADs full. Waiting ${WAIT_SECONDS}s. Keep this tab open; Ctrl-C to stop."
  sleep "$WAIT_SECONDS"
done
