#!/usr/bin/env bash
# Turn THIS host into a standby of <UPSTREAM_IP>. DESTROYS local postgres/redis data.
# Usage: scripts/reseed-standby.sh <UPSTREAM_IP> [--yes]
. "$(dirname "$0")/lib.sh"
UP=${1:?usage: $0 <UPSTREAM_IP> [--yes]}
if [ "${2:-}" != "--yes" ]; then
  read -r -p "This wipes local DB/Redis data and re-syncs from $UP. Type 'yes': " a
  [ "$a" = "yes" ] || die "aborted"
fi
require_env POSTGRES_USER POSTGRES_DB REPLICATION_PASSWORD REDIS_PASSWORD

log "Stopping stack and removing local data volumes"
dc --profile app down -v
"$REPO_DIR/scripts/gen-pg-certs.sh"
set_env PRIMARY_HOST "$UP"
set_env COMPOSE_FILE "docker-compose.yml:dr/compose.standby.yml"

log "Starting standby from $UP"
dc up -d postgres redis
wait_for "postgres ready" 900 pg_ready
wait_for "postgres in recovery" 60 pg_in_recovery
wait_for "redis replica linked" 180 redis_linked
log "Standby of $UP is running"
