#!/usr/bin/env bash
# Shared helpers for DR scripts. Source, don't execute.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"
mkdir -p .dr-state

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

REPL_SLOT="${REPL_SLOT:-standby_slot}"
REPL_APP_NAME="${REPL_APP_NAME:-standby1}"

log() { echo "[$(date -u +%FT%TZ)] $*"; }
die() { log "ERROR: $*"; exit 1; }
dc() { docker compose "$@"; }

require_env() {
  local v
  for v in "$@"; do
    [ -n "${!v:-}" ] || die "missing required variable $v in .env"
  done
}

# Run SQL inside the local postgres container (tuples only, unaligned).
pg_exec() {
  dc exec -T -u postgres postgres \
    psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "$1"
}

# redis-cli inside the local redis container (auth via REDISCLI_AUTH in the container).
redis_cli() { dc exec -T redis redis-cli "$@"; }

# Create or update KEY=VALUE in .env
set_env() {
  local key=$1 val=$2
  touch .env
  if grep -q "^${key}=" .env; then
    sed -i "s|^${key}=.*|${key}=${val}|" .env
  else
    echo "${key}=${val}" >> .env
  fi
  export "${key}=${val}"
}

# wait_for "description" timeout_seconds command...
wait_for() {
  local desc=$1 timeout=$2 t=0
  shift 2
  until "$@" >/dev/null 2>&1; do
    sleep 2
    t=$((t + 2))
    if [ "$t" -ge "$timeout" ]; then
      log "TIMEOUT waiting for: $desc"
      return 1
    fi
  done
  log "OK: $desc"
}

pg_ready() { dc exec -T postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"; }
pg_in_recovery() { [ "$(pg_exec 'SELECT pg_is_in_recovery()')" = "t" ]; }
pg_is_primary() { [ "$(pg_exec 'SELECT pg_is_in_recovery()')" = "f" ]; }

redis_linked() { redis_cli info replication | grep -q "master_link_status:up"; }
pg_streaming_count() { pg_exec "SELECT count(*) FROM pg_stat_replication WHERE state='streaming'"; }
pg_has_standby() { [ "$(pg_streaming_count)" -ge 1 ]; }
