#!/usr/bin/env bash
# Toggle synchronous replication on the CURRENT primary.
#   on  -> RPO = 0 (commits wait for the standby); writes stall if standby is down
#   off -> asynchronous (RPO = replication lag, typically < 1s)
. "$(dirname "$0")/lib.sh"
mode=${1:?usage: $0 on|off}
case "$mode" in
  on)
    wait_for "standby streaming" 60 pg_has_standby
    pg_exec "ALTER SYSTEM SET synchronous_standby_names = '${REPL_APP_NAME}'"
    pg_exec "SELECT pg_reload_conf()"
    sleep 2
    pg_exec "SELECT application_name, state, sync_state FROM pg_stat_replication"
    ;;
  off)
    pg_exec "ALTER SYSTEM RESET synchronous_standby_names"
    pg_exec "SELECT pg_reload_conf()"
    log "synchronous replication disabled"
    ;;
  *) die "usage: $0 on|off" ;;
esac
