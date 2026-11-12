#!/usr/bin/env bash
# Run ON THE PRIMARY host once, after the new images (REDIS_PASSWORD support) are deployed.
# Usage: scripts/primary-enable-replication.sh <DR_PUBLIC_IP> <PRIMARY_PUBLIC_IP>
# Both IPs are whitelisted for replication so failback works later.
# NOTE: recreates postgres + redis (a few seconds of downtime; queued jobs in Redis are
#       not persisted before this point because the original stack had no Redis volume).
. "$(dirname "$0")/lib.sh"

DR_IP=${1:?usage: $0 <DR_IP> <PRIMARY_IP>}
PRIMARY_IP=${2:?usage: $0 <DR_IP> <PRIMARY_IP>}
require_env POSTGRES_USER POSTGRES_DB REPLICATION_PASSWORD REDIS_PASSWORD

"$REPO_DIR/scripts/gen-pg-certs.sh"
set_env COMPOSE_FILE "docker-compose.yml:dr/compose.primary.yml"

log "Recreating postgres and redis with replication settings"
dc up -d postgres redis
wait_for "postgres ready" 120 pg_ready

log "Creating replication role and slot"
pg_exec "DO \$\$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname='replicator') THEN
    CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD '${REPLICATION_PASSWORD}';
  ELSE
    ALTER ROLE replicator WITH REPLICATION LOGIN PASSWORD '${REPLICATION_PASSWORD}';
  END IF;
END \$\$;"
pg_exec "SELECT pg_create_physical_replication_slot('${REPL_SLOT}')
         WHERE NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name='${REPL_SLOT}')" || true

for ip in "$DR_IP" "$PRIMARY_IP"; do
  line="hostssl replication replicator ${ip}/32 scram-sha-256"
  dc exec -T postgres sh -c "grep -qF '${line}' \"\$PGDATA/pg_hba.conf\" || echo '${line}' >> \"\$PGDATA/pg_hba.conf\""
done
pg_exec "SELECT pg_reload_conf()"

log "Bringing the rest of the stack up"
dc up -d --no-build
log "Done. Next: on the DR host run scripts/dr-setup.sh"
