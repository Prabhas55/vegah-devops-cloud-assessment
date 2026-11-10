#!/bin/bash
set -euo pipefail

# VEGAH Singapore DR Failover
# Safe by default: dry-run only.
# Actual failover should use the tested server-side automation script.

DR_HOST="54.169.230.0"
DR_REGION="ap-southeast-1"
PRIMARY_INSTANCE_ID="i-044897522a44948c4"

MODE="${1:---dry-run}"

echo "===================================="
echo " VEGAH DISASTER RECOVERY FAILOVER"
echo "===================================="

echo "Primary region: ap-south-1"
echo "DR region: $DR_REGION"
echo "DR host: $DR_HOST"
echo "Mode: $MODE"

if [[ "$MODE" != "--dry-run" && "$MODE" != "--execute" ]]; then
    echo "Usage: $0 [--dry-run|--execute]"
    exit 1
fi

echo
echo "[1/5] Checking AWS CLI availability..."
command -v aws >/dev/null || {
    echo "AWS CLI is not installed."
    exit 1
}

echo "[2/5] Checking primary EC2 instance status..."
aws ec2 describe-instances \
    --region ap-south-1 \
    --instance-ids "$PRIMARY_INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text

echo "[3/5] Checking DR server availability..."
curl --connect-timeout 5 -sS -o /dev/null \
    "http://$DR_HOST/health" || true

echo "[4/5] Failover execution requires verified database,
application, and replication status."

if [[ "$MODE" == "--dry-run" ]]; then
    echo "[5/5] DRY RUN complete. No infrastructure changes made."
    exit 0
fi

echo "This repository script is intentionally not authorized"
echo "to perform live failover."
echo "Use the tested server-side automation script after"
echo "manual outage confirmation and approval."
exit 2
