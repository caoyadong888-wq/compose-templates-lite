#!/usr/bin/env bash
# Start 01-nginx-https with a self-signed certificate and request the demo URL.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT/01-nginx-https" || exit 1

"$ROOT/01-nginx-https/scripts/gen-self-signed.sh"
docker compose up -d

ready=0
for _ in $(seq 1 40); do
  if curl -k -f -sS --max-time 3 https://localhost:8443/ -o /dev/null; then
    ready=1
    break
  fi
  sleep 2
done

if [ "$ready" -ne 1 ]; then
  echo "demo did not answer on https://localhost:8443" >&2
  docker compose ps >&2 || true
  docker compose logs --tail 80 >&2 || true
  exit 1
fi

echo "+ curl -k https://localhost:8443"
curl -k -f -sS https://localhost:8443/
echo
echo "Demo is up at https://localhost:8443"
echo "Stop it with: make demo-down"
