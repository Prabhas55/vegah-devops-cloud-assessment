#!/bin/bash
set -euo pipefail

# VEGAH controlled failback: Singapore to Mumbai.
# This script is a checklist, not an automatic failback tool.

echo "===================================="
echo " VEGAH DISASTER RECOVERY FAILBACK"
echo "===================================="

echo "Source primary: Singapore"
echo "Target primary: Mumbai"

steps=(
  "Confirm Mumbai infrastructure is healthy."
  "Stop new application writes and workers in Singapore."
  "Verify PostgreSQL replication and data consistency."
  "Verify the final WAL position before promotion."
  "Prepare and promote Mumbai PostgreSQL safely."
  "Start Mumbai backend and worker services."
  "Verify database writes, Redis and application health."
  "Restore normal primary-region traffic."
  "Verify DNS health checks and end-to-end job processing."
)

for i in "${!steps[@]}"; do
    echo "$((i + 1)). ${steps[$i]}"
done

echo
echo "No AWS or database changes were performed."
echo "Follow the approved manual failback runbook."
