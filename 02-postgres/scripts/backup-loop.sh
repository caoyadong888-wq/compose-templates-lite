#!/bin/sh
# Dump immediately, then sleep for the daily interval and dump again.
set -eu
interval="${BACKUP_INTERVAL_SECONDS:-86400}"
/bin/sh /scripts/backup-once.sh
while true; do
  sleep "$interval" &
  wait "$!"
  /bin/sh /scripts/backup-once.sh
done
