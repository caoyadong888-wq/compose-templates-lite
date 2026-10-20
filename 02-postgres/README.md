# 02-postgres

Postgres 16 with a healthcheck and a backup sidecar. Image: `postgres:16.15-alpine`.

The database container runs `pg_isready` against `POSTGRES_USER` and `POSTGRES_DB`. The backup container joins the database network namespace and connects to `127.0.0.1`. It waits until the healthcheck passes, writes one custom-format dump into `backups/`, then repeats every `BACKUP_INTERVAL_SECONDS` (default 86400, one day). Dumps older than `BACKUP_RETENTION_DAYS` (default 7) are deleted. The database container publishes the host port.

The example password is `change-me-now`. Change it in `.env` before you expose port 5432.

`initdb/01-schema.sql` creates a `backup_probe` table so a fresh data volume is not empty. Postgres only runs scripts in `docker-entrypoint-initdb.d` when the data volume is new.

## Quick start

```bash
docker compose up -d
docker compose exec postgres pg_isready -U app -d app
docker compose exec backup /bin/sh /scripts/backup-once.sh
ls -l backups
```

The sidecar already dumps once at start. The exec command writes another dump on demand.

Stop and delete the data volume:

```bash
docker compose down -v
```

`down -v` removes the named volume. Files in `backups/` stay on the host. Copy them off the machine if you need them.

## Restore

Dumps are `pg_dump -Fc` (custom format), with `--no-owner --no-acl`.

From this folder, with the stack running:

```bash
./scripts/restore.sh backups/app-YYYYMMDDTHHMMSSZ.dump
```

`scripts/restore.sh` runs:

```bash
docker compose exec -T postgres \
  pg_restore -U app -d app --clean --if-exists --no-owner --no-acl \
  < backups/app-YYYYMMDDTHHMMSSZ.dump
```

Replace the file name with the dump you want. `pg_restore` may print a warning when `--clean` drops an object that is not there yet. A non-zero status after that warning means the restore did not finish. Check the table:

```bash
docker compose exec postgres psql -U app -d app -c 'SELECT id, note FROM backup_probe'
```

To restore into an empty volume, start the stack, wait until `pg_isready` succeeds, then run `scripts/restore.sh`. `--clean --if-exists` replaces objects that the init script already created.

Manual form, if you are not using the script:

```bash
docker compose exec -T postgres \
  pg_restore -U "${POSTGRES_USER:-app}" -d "${POSTGRES_DB:-app}" \
  --clean --if-exists --no-owner --no-acl \
  < backups/your.dump
```

## Ports

| Host port | Container | Purpose |
| --- | --- | --- |
| `POSTGRES_PORT` (5432) | 5432 | Postgres |

## 中文说明

Postgres 16，带健康检查和备份边车。镜像 `postgres:16.15-alpine`。备份容器加入数据库的网络命名空间，连 `127.0.0.1`。数据库健康后立刻 `pg_dump -Fc` 到 `backups/`，之后按 `BACKUP_INTERVAL_SECONDS`（默认每天）再备一次。超过 `BACKUP_RETENTION_DAYS`（默认 7 天）的 dump 会被删掉。宿主机端口由数据库容器发布。

恢复：

```bash
./scripts/restore.sh backups/app-YYYYMMDDTHHMMSSZ.dump
```

脚本对运行中的库执行 `pg_restore --clean --if-exists --no-owner --no-acl`。示例口令是 `change-me-now`，对外暴露端口前请改掉。`docker compose down -v` 会删掉数据卷，但 `backups/` 里的文件还在宿主机上。
