#!/usr/bin/env bash
# Run from your laptop (or the GitHub Actions runner) with SSH access to both hosts.
# Moves production from the DR host back to the ORIGINAL primary with no data loss:
#   1 re-seed original primary as a standby of DR   2 wait for lag = 0
#   3 stop DR app (short write freeze)              4 wait for lag = 0 again
#   5 promote original primary (full stack)         6 re-seed DR as standby of original
# Env: PRIMARY_IP, DR_IP, SSH_USER (default ubuntu), SSH_KEY_PRIMARY, SSH_KEY_DR, REMOTE_DIR
set -euo pipefail
: "${PRIMARY_IP:?}" "${DR_IP:?}"
SSH_USER=${SSH_USER:-ubuntu}
REMOTE_DIR=${REMOTE_DIR:-~/vegah-devops-cloud-assessment}
SSH_OPTS="-o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30"
p() { ssh $SSH_OPTS ${SSH_KEY_PRIMARY:+-i "$SSH_KEY_PRIMARY"} "$SSH_USER@$PRIMARY_IP" "cd $REMOTE_DIR && $*"; }
d() { ssh $SSH_OPTS ${SSH_KEY_DR:+-i "$SSH_KEY_DR"} "$SSH_USER@$DR_IP" "cd $REMOTE_DIR && $*"; }
log() { echo "[$(date -u +%FT%TZ)] $*"; }

lag_zero() { d "./scripts/lag-zero.sh" >/dev/null 2>&1; }
wait_lag_zero() {
  local t=0
  until lag_zero; do
    sleep 3; t=$((t + 3))
    [ "$t" -lt 900 ] || { log "timeout waiting for replication lag = 0"; exit 1; }
  done
  log "replication lag = 0"
}

START=$(date +%s)
log "1/6 re-seeding original primary ($PRIMARY_IP) as standby of DR ($DR_IP)"
p "./scripts/reseed-standby.sh $DR_IP --yes"
log "2/6 waiting for original primary to catch up"
wait_lag_zero
log "3/6 stopping DR application tier (write freeze starts)"
d "docker compose --profile app stop nginx frontend backend worker"
log "4/6 final catch-up"
wait_lag_zero
FREEZE=$(date +%s)
log "5/6 promoting original primary"
p "./scripts/promote.sh --primary-overlay"
log "6/6 re-seeding DR as standby of original primary"
d "./scripts/reseed-standby.sh $PRIMARY_IP --yes"
END=$(date +%s)
log "FAILBACK COMPLETE in $((END - START))s (write freeze ~$((END - FREEZE))s incl. DR re-seed; app downtime is only steps 3-5)"
