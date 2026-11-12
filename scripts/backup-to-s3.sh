#!/usr/bin/env bash
# Runs on the DR host (cron). Takes logical backups from the local standby/replica and
# uploads them to the S3 bucket in the DR region (extra protection beyond replication:
# point-in-time-ish recovery from corruption/accidental deletes).
. "$(dirname "$0")/lib.sh"
require_env BACKUP_BUCKET POSTGRES_USER POSTGRES_DB
TS=$(date -u +%Y%m%dT%H%M%SZ); TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

log "pg_dump"
dc exec -T -u postgres postgres pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc > "$TMP/postgres.dump"
log "redis RDB snapshot"
dc exec -T redis sh -c 'redis-cli --rdb /tmp/backup.rdb >/dev/null'
dc cp redis:/tmp/backup.rdb "$TMP/redis.rdb"

aws s3 cp "$TMP/postgres.dump" "s3://${BACKUP_BUCKET}/postgres/${TS}.dump" --only-show-errors
aws s3 cp "$TMP/redis.rdb"     "s3://${BACKUP_BUCKET}/redis/${TS}.rdb"     --only-show-errors
log "backup uploaded: s3://${BACKUP_BUCKET}/*/${TS}.*"
