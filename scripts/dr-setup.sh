#!/usr/bin/env bash
# Run ON THE DR host after Terraform + bootstrap. Requires .env (see .env.example).
# Starts the warm data tier (postgres standby + redis replica), pre-pulls app images,
# installs the backup cron and (optionally) the auto-failover watchdog.
. "$(dirname "$0")/lib.sh"
require_env POSTGRES_USER POSTGRES_DB REPLICATION_PASSWORD REDIS_PASSWORD PRIMARY_HOST

"$REPO_DIR/scripts/gen-pg-certs.sh"
set_env COMPOSE_FILE "docker-compose.yml:dr/compose.standby.yml"

log "Starting standby data tier (base backup from ${PRIMARY_HOST})"
dc up -d postgres redis
wait_for "postgres standby accepting connections" 600 pg_ready
wait_for "postgres in recovery (standby)" 60 pg_in_recovery
if [ -n "${DB_USER:-}" ]; then
  dc exec -T -e PGPASSWORD="${DB_PASSWORD}" postgres \
    psql -h postgres -U "${DB_USER}" -d "${DB_NAME}" -tAc "select 1" >/dev/null \
    || die "DB_USER/DB_PASSWORD/DB_NAME in .env cannot log in to the standby (must match the primary)"
fi
wait_for "redis replica linked" 120 redis_linked

log "Pre-pulling application images (reduces RTO)"
dc --profile app pull frontend backend worker nginx || log "WARN: pull failed (docker login ghcr.io needed?)"

if [ -n "${BACKUP_BUCKET:-}" ]; then
  CRON="0 * * * * cd ${REPO_DIR} && ./scripts/backup-to-s3.sh >> ${REPO_DIR}/.dr-state/backup.log 2>&1"
  ( crontab -l 2>/dev/null | grep -v backup-to-s3.sh; echo "$CRON" ) | crontab -
  log "Hourly S3 backup cron installed"
fi

if [ "${AUTO_FAILOVER:-false}" = "true" ]; then
  sed -e "s|__REPO_DIR__|${REPO_DIR}|g" -e "s|__USER__|$(id -un)|g" \
    dr/dr-watchdog.service | sudo tee /etc/systemd/system/dr-watchdog.service >/dev/null
  sudo systemctl daemon-reload
  sudo systemctl enable --now dr-watchdog.service
  log "Auto-failover watchdog enabled (journalctl -u dr-watchdog -f)"
else
  log "AUTO_FAILOVER=false -> run scripts/failover.sh manually when needed"
fi

pg_exec "SELECT 'standby replay lag (s): ' || COALESCE(EXTRACT(EPOCH FROM now() - pg_last_xact_replay_timestamp())::int::text, 'n/a')"
log "DR host ready."
