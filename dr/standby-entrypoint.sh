#!/bin/sh
# Entrypoint for a PostgreSQL streaming-replication standby (postgres:16-alpine).
# - Empty data dir  -> pg_basebackup from PRIMARY_HOST (creates standby.signal)
# - Existing data   -> start as-is (standby, or a promoted primary after failover)
set -eu

PGDATA="${PGDATA:-/var/lib/postgresql/data}"

if [ ! -s "$PGDATA/PG_VERSION" ]; then
  echo "[standby] empty data dir -> bootstrapping from ${PRIMARY_HOST}:${PRIMARY_PORT}"
  mkdir -p "$PGDATA"
  chown postgres:postgres "$PGDATA"
  chmod 700 "$PGDATA"

  until pg_isready -h "$PRIMARY_HOST" -p "$PRIMARY_PORT" >/dev/null 2>&1; do
    echo "[standby] waiting for primary ${PRIMARY_HOST}:${PRIMARY_PORT} ..."
    sleep 3
  done

  su-exec postgres env PGPASSWORD="$REPLICATION_PASSWORD" PGSSLMODE=require \
    pg_basebackup -h "$PRIMARY_HOST" -p "$PRIMARY_PORT" -U "$REPLICATION_USER" \
      -D "$PGDATA" -X stream -S "$REPL_SLOT" -R -P

  # Later settings win: make sure application_name and slot are explicit.
  cat >> "$PGDATA/postgresql.auto.conf" <<CONF
primary_conninfo = 'host=${PRIMARY_HOST} port=${PRIMARY_PORT} user=${REPLICATION_USER} password=${REPLICATION_PASSWORD} application_name=${REPL_APP_NAME} sslmode=require'
primary_slot_name = '${REPL_SLOT}'
CONF
  chown postgres:postgres "$PGDATA/postgresql.auto.conf"
  echo "[standby] base backup complete"
fi

exec su-exec postgres postgres \
  -c listen_addresses='*' \
  -c wal_level=replica \
  -c max_wal_senders=10 \
  -c max_replication_slots=10 \
  -c wal_keep_size=256MB \
  -c max_slot_wal_keep_size=2GB \
  -c hot_standby=on \
  -c ssl=on \
  -c ssl_cert_file=/certs/server.crt \
  -c ssl_key_file=/certs/server.key
