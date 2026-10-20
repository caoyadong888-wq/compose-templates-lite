#!/bin/sh
# Restore a custom-format dump produced by scripts/backup-once.sh.
# Usage: scripts/restore.sh backups/app-YYYYMMDDTHHMMSSZ.dump
set -eu
cd "$(dirname "$0")/.." || exit 1
if [ "$#" -ne 1 ]; then
  echo "usage: scripts/restore.sh backups/<file>.dump" >&2
  exit 2
fi
dump="$1"
if [ ! -f "$dump" ]; then
  echo "dump not found: $dump" >&2
  exit 1
fi
user="${POSTGRES_USER:-app}"
db="${POSTGRES_DB:-app}"
docker compose exec -T postgres \
  pg_restore -U "$user" -d "$db" --clean --if-exists --no-owner --no-acl \
  <"$dump"
echo "restored ${dump} into ${db}"
