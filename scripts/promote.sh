#!/usr/bin/env bash
# Promote THIS host's standby to primary and start the application tier.
# Usage: scripts/promote.sh [--primary-overlay]
#   --primary-overlay : after promotion switch COMPOSE_FILE to dr/compose.primary.yml
#                       (used when failing back to the ORIGINAL primary host).
. "$(dirname "$0")/lib.sh"
START=$(date +%s)
require_env POSTGRES_USER POSTGRES_DB

if pg_in_recovery; then
  log "Promoting PostgreSQL standby"
  pg_exec "SELECT pg_promote(true, 60)"
  wait_for "postgres promoted (read/write)" 90 pg_is_primary
else
  log "PostgreSQL already primary"
fi

# Never let a promoted node wait for a (dead) synchronous standby.
pg_exec "ALTER SYSTEM RESET synchronous_standby_names" >/dev/null
pg_exec "SELECT pg_reload_conf()" >/dev/null
# Slot for a future standby (failback target).
pg_exec "SELECT pg_create_physical_replication_slot('${REPL_SLOT}')
         WHERE NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name='${REPL_SLOT}')" >/dev/null || true

log "Promoting Redis replica"
redis_cli REPLICAOF NO ONE
dc exec -T redis touch /data/promoted   # survive container restarts as master

if [ "${1:-}" = "--primary-overlay" ]; then
  set_env COMPOSE_FILE "docker-compose.yml:dr/compose.primary.yml"
  log "Switching to primary overlay and starting full stack"
  dc up -d --no-build
else
  log "Refreshing application images"
  dc --profile app pull frontend backend worker nginx || log "WARN: image pull failed, using cached images"
  log "Starting application tier"
  dc --profile app up -d --no-build
fi

wait_for "application healthy via nginx (/api/health)" 180 curl -fsS http://localhost/api/health
END=$(date +%s)
log "PROMOTION COMPLETE in $((END - START))s"
echo "$START $END" > .dr-state/last-promotion
