#!/usr/bin/env bash
# Generate a self-signed TLS cert so replication traffic between regions is encrypted.
# Run once per host (certs are not committed).
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p dr/certs
if [ ! -f dr/certs/server.key ]; then
  openssl req -new -x509 -days 3650 -nodes -subj "/CN=vegah-postgres" \
    -keyout dr/certs/server.key -out dr/certs/server.crt
fi
chmod 600 dr/certs/server.key
chmod 644 dr/certs/server.crt
# uid 70 = postgres user in postgres:16-alpine
sudo chown 70:70 dr/certs/server.key dr/certs/server.crt
echo "certs ready in dr/certs"
