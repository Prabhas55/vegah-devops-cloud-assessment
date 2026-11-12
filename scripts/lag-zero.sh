#!/usr/bin/env bash
# Exit 0 only when exactly one standby is streaming and fully caught up (run on the upstream host).
. "$(dirname "$0")/lib.sh"
[ "$(pg_exec "SELECT count(*) FROM pg_stat_replication WHERE state='streaming' AND sent_lsn = replay_lsn")" = "1" ]
