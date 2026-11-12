#!/usr/bin/env bash
# Run ON THE PRIMARY host: hard-kill the whole stack to simulate a regional/host failure.
. "$(dirname "$0")/lib.sh"
log "!!! SIMULATING DISASTER: killing all containers on the primary !!!"
date +%s > .dr-state/outage-start
dc kill nginx frontend backend worker postgres redis
dc ps
log "Outage started at $(cat .dr-state/outage-start) (epoch). Do NOT restart this host until DR has taken over (split-brain)."
