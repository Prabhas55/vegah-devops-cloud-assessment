#!/usr/bin/env bash
# Run from your laptop during the drill. Probes the public URL every second and
# reports the measured downtime (= observed RTO) when service returns.
# Usage: scripts/measure-rto.sh <HEALTH_URL> [DNS_NAME]
URL=${1:?usage: $0 <HEALTH_URL e.g. http://app.example.com/api/health> [DNS_NAME]}
DNS=${2:-}
down_at=""
while true; do
  now=$(date +%s.%N)
  code=$(curl -s -o /dev/null -m 2 -w '%{http_code}' "$URL" || true)
  ip=""; [ -n "$DNS" ] && ip=$(dig +short "$DNS" | head -1)
  if [ "$code" = "200" ]; then
    if [ -n "$down_at" ]; then
      printf '%s UP   (%s) %s\n>>> MEASURED RTO: %.1f seconds\n' "$(date +%T)" "$code" "$ip" "$(echo "$now - $down_at" | bc)"
      down_at=""
    else
      printf '%s UP   (%s) %s\n' "$(date +%T)" "$code" "$ip"
    fi
  else
    [ -z "$down_at" ] && down_at=$now && echo ">>> outage detected"
    printf '%s DOWN (%s) %s\n' "$(date +%T)" "$code" "$ip"
  fi
  sleep 1
done
