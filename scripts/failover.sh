#!/usr/bin/env bash
# Failover entrypoint on the DR host (manual or called by watchdog).
set -euo pipefail

. "$(dirname "$0")/lib.sh"

log "=== FAILOVER STARTED ==="

log "Step 1: Fencing Mumbai primary."
"$REPO_DIR/scripts/fence-primary.sh"

log "Step 2: Promoting Singapore DR."
"$REPO_DIR/scripts/promote.sh"

log "Step 3: Checking promoted database."
pg_exec "SELECT status, count(*) FROM jobs GROUP BY status ORDER BY 1"

log "=== FAILOVER COMPLETE ==="
