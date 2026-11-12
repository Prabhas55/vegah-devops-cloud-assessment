#!/usr/bin/env bash
# Stop and verify the Mumbai primary before allowing DR promotion.
set -euo pipefail

. "$(dirname "$0")/lib.sh"

require_env PRIMARY_INSTANCE_ID PRIMARY_AWS_REGION

INSTANCE_ID="$PRIMARY_INSTANCE_ID"
REGION="$PRIMARY_AWS_REGION"

log "Checking Mumbai primary state: $INSTANCE_ID"

get_state() {
  aws ec2 describe-instances \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text
}

STATE="$(get_state)" || die "Unable to query primary instance state."

case "$STATE" in
  stopped)
    log "Primary is already stopped. Fence confirmed."
    ;;
  running)
    log "Primary is running. Requesting EC2 stop."
    aws ec2 stop-instances \
      --region "$REGION" \
      --instance-ids "$INSTANCE_ID" \
      >/dev/null || die "AWS refused the primary stop request."

    log "Waiting for primary to reach stopped state."
    aws ec2 wait instance-stopped \
      --region "$REGION" \
      --instance-ids "$INSTANCE_ID" \
      || die "Timed out waiting for primary to stop."
    ;;
  *)
    die "Primary state is '$STATE'. Cannot safely confirm fencing."
    ;;
esac

FINAL_STATE="$(get_state)" || die "Could not verify final primary state."

[ "$FINAL_STATE" = "stopped" ] \
  || die "Fencing verification failed. Final state: $FINAL_STATE"

log "FENCING VERIFIED: Mumbai primary is stopped."
