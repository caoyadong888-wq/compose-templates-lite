#!/bin/sh
# One custom-format pg_dump into /backups, then drop dumps past retention.
set -eu
PGHOST="${PGHOST:-postgres}"
PGUSER="${PGUSER:-app}"
PGDATABASE="${PGDATABASE:-app}"
PGPASSWORD="${PGPASSWORD:-change-me-now}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
export PGHOST PGUSER PGDATABASE PGPASSWORD

mkdir -p /backups

i=0
until pg_isready -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" >/dev/null 2>&1; do
  i=$((i + 1))
  if [ "$i" -gt 30 ]; then
    echo "postgres not ready" >&2
    exit 1
  fi
  sleep 1
done

ts="$(date -u +%Y%m%dT%H%M%SZ)"
out="/backups/${PGDATABASE}-${ts}.dump"
pg_dump -Fc --no-owner --no-acl -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -f "$out"
find /backups -type f -name '*.dump' -mtime +"$RETENTION_DAYS" -delete
echo "backup wrote ${out}"
