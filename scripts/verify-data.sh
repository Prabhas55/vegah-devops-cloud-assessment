#!/usr/bin/env bash
# Data-integrity check through the public API (works against primary or DR).
#   scripts/verify-data.sh snapshot <BASE_URL>   # before the disaster
#   scripts/verify-data.sh compare  <BASE_URL>   # after failover: every snapshot id must exist
set -euo pipefail
cd "$(dirname "$0")/.."; mkdir -p .dr-state
mode=${1:?usage: $0 snapshot|compare <BASE_URL>}; URL=${2:?usage: $0 snapshot|compare <BASE_URL>}
ids() { curl -fsS "$URL/api/jobs" | jq -r '.[].id' | sort; }
case "$mode" in
  snapshot)
    ids > .dr-state/jobs.snapshot
    echo "snapshot: $(wc -l < .dr-state/jobs.snapshot) jobs, checksum $(md5sum < .dr-state/jobs.snapshot | cut -c1-12)"
    ;;
  compare)
    ids > .dr-state/jobs.after
    missing=$(comm -23 .dr-state/jobs.snapshot .dr-state/jobs.after | wc -l)
    echo "before: $(wc -l < .dr-state/jobs.snapshot) jobs | after: $(wc -l < .dr-state/jobs.after) jobs | missing: $missing"
    if [ "$missing" -eq 0 ]; then echo "RESULT: DATA INTACT (zero data loss)"; else echo "RESULT: DATA LOSS DETECTED"; comm -23 .dr-state/jobs.snapshot .dr-state/jobs.after; exit 1; fi
    ;;
  *) echo "usage: $0 snapshot|compare <BASE_URL>"; exit 1 ;;
esac
