#!/usr/bin/env bash
# Preview checks: nginx HTTPS demo and Postgres backup. Removes containers and volumes after.
set -u
set -o pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

LOG="$(mktemp)"
DETAIL="$(mktemp)"
VERSIONS="$(mktemp)"
FAILS=0

record() {
  printf '%s\n' "$1" | tee -a "$LOG"
}

mark() {
  local name="$1"
  local ok="$2"
  if [ "$ok" -eq 0 ]; then
    record "PASS: $name"
  else
    record "FAIL: $name"
    FAILS=$((FAILS + 1))
  fi
}

detail() {
  printf '\n===== %s =====\n' "$1" >>"$DETAIL"
  shift
  "$@" >>"$DETAIL" 2>&1
}

anonymize_file() {
  python3 - "$1" "$2" <<'PY'
import re, socket, sys
src, dest = sys.argv[1], sys.argv[2]
host = socket.gethostname()
data = open(src, encoding="utf-8", errors="replace").read()
if host:
    data = data.replace(host, "demo-host")
def repl(match):
    ip = match.group(0)
    if ip.startswith("127.") or ip.startswith("192.0.2.") or ip == "0.0.0.0":
        return ip
    try:
        nums = [int(part) for part in ip.split(".")]
    except ValueError:
        return ip
    if any(num > 255 for num in nums):
        return ip
    return "192.0.2.%d" % ((nums[3] % 254) + 1)
data = re.sub(r"\b(?:\d{1,3}\.){3}\d{1,3}\b", repl, data)
open(dest, "w", encoding="utf-8").write(data)
PY
}

compose() {
  local dir="$1"
  shift
  docker compose --project-directory "$ROOT/$dir" -f "$ROOT/$dir/docker-compose.yml" "$@"
}

down_dir() {
  local dir="$1"
  docker compose --project-directory "$ROOT/$dir" -f "$ROOT/$dir/docker-compose.yml" down -v --remove-orphans >>"$DETAIL" 2>&1 || true
}

write_results() {
  local checks body versions
  checks="$(mktemp)"
  body="$(mktemp)"
  versions="$(mktemp)"
  anonymize_file "$LOG" "$checks"
  anonymize_file "$DETAIL" "$body"
  anonymize_file "$VERSIONS" "$versions"
  {
    echo "# Test results"
    echo
    echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo
    echo "## Tool versions"
    echo
    echo '```'
    cat "$versions"
    echo '```'
    echo
    echo "## Checks"
    echo
    echo '```'
    cat "$checks"
    echo '```'
    echo
    echo "## Command output"
    echo
    echo '```'
    cat "$body"
    echo '```'
  } >"$ROOT/tests/RESULTS.md"
  rm -f "$checks" "$body" "$versions"
}

cleanup() {
  down_dir 01-nginx-https
  down_dir 02-postgres
  rm -f "$ROOT/02-postgres/backups/"*.dump
  rm -f "$ROOT/01-nginx-https/certs/"*.pem
  write_results
  rm -f "$LOG" "$DETAIL" "$VERSIONS"
  if [ "$FAILS" -ne 0 ]; then
    exit 1
  fi
}
trap cleanup EXIT

{
  echo "date $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  docker version --format 'docker client {{.Client.Version}} server {{.Server.Version}}'
  docker compose version
  python3 --version
  openssl version
  curl --version | head -n 1
} >>"$VERSIONS" 2>&1 || true

record "Root: demo-host pack compose-templates-lite"

config_one() {
  local dir="$1"
  local label="$2"
  shift 2
  if detail "$label" docker compose --project-directory "$ROOT/$dir" -f "$ROOT/$dir/docker-compose.yml" "$@" config; then
    mark "$label" 0
  else
    mark "$label" 1
  fi
}

config_one 01-nginx-https "docker compose config 01-nginx-https"
config_one 01-nginx-https "docker compose config 01-nginx-https profile letsencrypt" --profile letsencrypt
config_one 02-postgres "docker compose config 02-postgres"

if grep -n ':latest' \
  "$ROOT/01-nginx-https/docker-compose.yml" \
  "$ROOT/02-postgres/docker-compose.yml" \
  >>"$DETAIL" 2>&1; then
  mark "compose files pin image tags" 1
else
  mark "compose files pin image tags" 0
fi

SHELL_FILES=(
  demo.sh
  tests/run_tests.sh
  01-nginx-https/scripts/gen-self-signed.sh
  01-nginx-https/scripts/renew-loop.sh
  01-nginx-https/scripts/export-certs.sh
  01-nginx-https/scripts/issue-cert.sh
  02-postgres/scripts/backup-once.sh
  02-postgres/scripts/backup-loop.sh
  02-postgres/scripts/restore.sh
)
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck --version >>"$VERSIONS" 2>&1 || true
  if detail "shellcheck" shellcheck "${SHELL_FILES[@]}"; then
    mark "shellcheck" 0
  else
    mark "shellcheck" 1
  fi
else
  docker run --rm --entrypoint shellcheck koalaman/shellcheck:stable --version >>"$VERSIONS" 2>&1 || true
  if detail "shellcheck" docker run --rm -v "$ROOT:/repo:ro" -w /repo koalaman/shellcheck:stable "${SHELL_FILES[@]}"; then
    mark "shellcheck" 0
  else
    mark "shellcheck" 1
  fi
fi

down_dir 01-nginx-https
demo_log="$(mktemp)"
if make demo >"$demo_log" 2>&1; then
  mark "make demo curls https://localhost:8443" 0
else
  mark "make demo curls https://localhost:8443" 1
  compose 01-nginx-https logs --tail 80 >>"$demo_log" 2>&1 || true
fi
cat "$demo_log" >>"$DETAIL"
rm -f "$demo_log"

body="$(mktemp)"
if curl -k -f -sS --max-time 10 https://localhost:8443/ >"$body" 2>>"$DETAIL"; then
  if grep -q 'compose-templates-nginx-ok' "$body"; then
    mark "01 nginx https health" 0
  else
    mark "01 nginx https health" 1
  fi
else
  mark "01 nginx https health" 1
fi
rm -f "$body"
down_dir 01-nginx-https

down_dir 02-postgres
rm -f "$ROOT/02-postgres/backups/"*.dump
if detail "02 up" compose 02-postgres up -d; then
  mark "02 postgres up" 0
else
  mark "02 postgres up" 1
fi

pg_ok=1
i=0
while [ "$i" -lt 40 ]; do
  if compose 02-postgres exec -T postgres pg_isready -U app -d app >>"$DETAIL" 2>&1; then
    pg_ok=0
    break
  fi
  i=$((i + 1))
  sleep 2
done
mark "02 pg_isready" "$pg_ok"

backup_ok=1
i=0
while [ "$i" -lt 30 ]; do
  if compose 02-postgres exec -T backup /bin/sh /scripts/backup-once.sh >>"$DETAIL" 2>&1; then
    backup_ok=0
    break
  fi
  i=$((i + 1))
  sleep 2
done
mark "02 backup command" "$backup_ok"

dump_ok=1
shopt -s nullglob
for dump in "$ROOT/02-postgres/backups/"*.dump; do
  if [ -s "$dump" ]; then
    dump_ok=0
    echo "dump file $(basename "$dump") size $(wc -c <"$dump")" >>"$DETAIL"
  fi
done
shopt -u nullglob
mark "02 backup dump exists" "$dump_ok"
down_dir 02-postgres
rm -f "$ROOT/02-postgres/backups/"*.dump

left=0
for dir in 01-nginx-https 02-postgres; do
  ids="$(compose "$dir" ps -q || true)"
  if [ -n "$ids" ]; then
    left=1
    echo "still running in $dir: $ids" >>"$DETAIL"
  fi
done
mark "cleanup down -v" "$left"
record "failures: $FAILS"
