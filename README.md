# Docker Compose Deployment Templates (preview)

Free preview of the Compose templates pack. This subset is the nginx HTTPS stack and the Postgres backup stack. Image tags are pinned. The files do not contain live credentials.

In each stack one service owns the network namespace and publishes the host ports. The other service joins that namespace and connects on `127.0.0.1`.

## What it is

| Folder | Contents |
| --- | --- |
| `01-nginx-https` | nginx reverse proxy, self-signed demo on `https://localhost:8443`, Certbot webroot renewal profile |
| `02-postgres` | Postgres 16, healthcheck, daily `pg_dump` sidecar, retention, restore script |

Host ports: nginx 8080 and 8443, Postgres 5432. The example password is `change-me-now`. Change it before you expose the database port.

## Quick start

Docker Engine 24 or newer, Docker Compose v2, curl, and OpenSSL.

```bash
make demo
```

That is the same as `./demo.sh`. It writes a localhost certificate, starts `01-nginx-https`, and runs `curl -k https://localhost:8443`. The body contains `compose-templates-nginx-ok`.

```bash
make demo-down
docker compose -f 02-postgres/docker-compose.yml up -d
docker compose -f 02-postgres/docker-compose.yml exec postgres pg_isready -U app -d app
bash tests/run_tests.sh
```

## One-click demo

```bash
make demo
```

or

```bash
./demo.sh
```

## Deliverables / 交付物清单

- `01-nginx-https/` nginx reverse proxy, self-signed demo, Certbot webroot profile, issue and renew scripts
- `02-postgres/` Postgres 16, healthcheck, daily backup sidecar, retention, `scripts/restore.sh`
- `demo.sh` and `Makefile`
- `tests/run_tests.sh` and the `tests/RESULTS.md` it writes
- `screenshots/` PNG captures of real demo and backup command output
- `LICENSE.txt` (MIT)

## Estimated setup time / 预计部署时间

About 15 minutes to run the demo on a machine that already has Docker. About 30 minutes to copy a template, change the published ports, and replace the example password and domain.

## Requirements

- Docker Engine 24 or newer
- Docker Compose v2.20 or newer
- curl and OpenSSL
- Free host ports 8080, 8443, and 5432

## License

`LICENSE.txt` is the MIT license.

## Full version / 完整版

The full pack adds monitoring, the example application stack, the changelog, marketing images, and a compose-config workflow.

Only in the full version:

- `03-monitoring` — Prometheus, node-exporter, Grafana with a provisioned Prometheus datasource, optional cAdvisor profile
- `04-app-stack` — whoami behind nginx, plus Postgres 16
- `CHANGELOG.md`
- `marketing/` — listing copy, `make_images.py`, `cover.png`, `thumb.png`
- `.github/workflows/compose-config.yml`

Full version: GUMROAD_URL

The $9 n8n DevOps Automation Pack is a separate product: https://caoyadong.gumroad.com/l/yvmcqj

## 中文说明

### 这是什么

这是 Compose 部署模板的免费预览，只包含 nginx HTTPS 和 Postgres 备份。镜像标签已钉死。文件里没有可用的真实口令。每个栈由一个服务占用网络命名空间并发布端口，另一个服务加入该命名空间，通过 `127.0.0.1` 连接。

| 目录 | 内容 |
| --- | --- |
| `01-nginx-https` | nginx 反向代理。演示模式用自签证书，地址是 `https://localhost:8443`。另有 Certbot webroot 续期 profile |
| `02-postgres` | Postgres 16、健康检查、每天 `pg_dump` 的边车、保留天数、恢复脚本 |

端口：nginx 8080 和 8443，Postgres 5432。示例口令是 `change-me-now`。把数据库端口暴露出去之前请先改口令。

### 快速开始

需要 Docker Engine 24+、Docker Compose v2、curl 和 OpenSSL。

```bash
make demo
```

这和 `./demo.sh` 相同。它写入 localhost 证书，启动 nginx 模板，并执行 `curl -k https://localhost:8443`。正文里有 `compose-templates-nginx-ok`。

```bash
make demo-down
docker compose -f 02-postgres/docker-compose.yml up -d
bash tests/run_tests.sh
```

### 一键演示

```bash
make demo
```

或

```bash
./demo.sh
```

### Deliverables / 交付物清单

- `01-nginx-https/`：nginx 反向代理、自签演示、Certbot webroot profile、申请和续期脚本
- `02-postgres/`：Postgres 16、健康检查、每日备份边车、保留策略、`scripts/restore.sh`
- `demo.sh` 和 `Makefile`
- `tests/run_tests.sh`，以及它写出的 `tests/RESULTS.md`
- `screenshots/`：演示和备份命令的真实输出截图
- `LICENSE.txt`（MIT）

### Estimated setup time / 预计部署时间

已安装 Docker 时，演示大约 15 分钟。复制模板、改端口、换掉示例口令和域名，大约 30 分钟。

### 环境要求

- Docker Engine 24 或更新版本
- Docker Compose v2.20 或更新版本
- curl 和 OpenSSL
- 空闲端口 8080、8443、5432

### 许可

`LICENSE.txt` 是 MIT 许可。

### Full version / 完整版

完整版另有监控栈、示例应用栈、更新日志、商品图，以及 compose 配置检查的 workflow。

只在完整版里：

- `03-monitoring` — Prometheus、node-exporter、已预置 Prometheus 数据源的 Grafana，可选 cAdvisor profile
- `04-app-stack` — nginx 反代 whoami，外加 Postgres 16
- `CHANGELOG.md`
- `marketing/` — 商品文案、`make_images.py`、`cover.png`、`thumb.png`
- `.github/workflows/compose-config.yml`

完整版：GUMROAD_URL

9 美元的 n8n DevOps Automation Pack 是另一个产品：https://caoyadong.gumroad.com/l/yvmcqj
