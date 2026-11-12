#!/usr/bin/env bash
# Runs on the DR host (systemd). If the primary stays unhealthy for
# WATCHDOG_THRESHOLD consecutive checks, run failover.sh automatically.
# Trade-off: a network partition between regions could trigger a false failover
# (split-brain risk) -> set AUTO_FAILOVER=false for manual approval.
. "$(dirname "$0")/lib.sh"
require_env PRIMARY_HOST
URL="${PRIMARY_HEALTH_URL:-http://${PRIMARY_HOST}/api/health}"
INTERVAL="${WATCHDOG_INTERVAL:-10}"
THRESHOLD="${WATCHDOG_THRESHOLD:-6}"
fails=0
log "watchdog watching $URL every ${INTERVAL}s (threshold ${THRESHOLD})"
while true; do
  if pg_is_primary 2>/dev/null; then
    log "this node is no longer a standby; watchdog exiting"
    exit 0
  fi
  if curl -fsS -m 5 -o /dev/null "$URL"; then
    fails=0
  else
    fails=$((fails + 1))
    log "primary health check failed (${fails}/${THRESHOLD})"
    if [ "$fails" -ge "$THRESHOLD" ]; then
      if [ "${AUTO_FAILOVER:-false}" = "true" ]; then
        log "Failure threshold reached. Starting fenced failover."
        "$REPO_DIR/scripts/failover.sh"
        exit $?
      else
        log "Failure threshold reached, but AUTO_FAILOVER=false."
        log "Automatic promotion disabled. Manual intervention required."
        exit 1
      fi
    fi
  fi
  sleep "$INTERVAL"
done
