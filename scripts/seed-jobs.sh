#!/usr/bin/env bash
# Create N jobs through the public API and wait until they complete.
# Usage: scripts/seed-jobs.sh <BASE_URL> [N=5]     e.g. http://app.example.com
set -euo pipefail
URL=${1:?usage: $0 <BASE_URL> [N]}; N=${2:-5}
ids=()
for i in $(seq 1 "$N"); do
  id=$(curl -fsS -X POST "$URL/api/jobs" -H 'Content-Type: application/json' \
        -d "{\"task\":\"DR demo job $i $(date +%s)\"}" | jq -r .id)
  ids+=("$id"); echo "submitted $id"
done
for id in "${ids[@]}"; do
  until [ "$(curl -fsS "$URL/api/jobs/$id" | jq -r .status)" = "COMPLETED" ]; do sleep 2; done
  echo "completed $id"
done
