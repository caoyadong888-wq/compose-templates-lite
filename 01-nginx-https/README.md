# 01-nginx-https

nginx reverse proxy with two modes.

**Demo mode (default).** `scripts/gen-self-signed.sh` writes a localhost certificate into `certs/`. nginx listens on host port 8443 (container port 443) and proxies to the backend on `127.0.0.1:8081`. The backend container owns the network namespace and the published ports. nginx joins that namespace, so the two processes talk on localhost instead of across a bridge. Port 80 answers `/.well-known/acme-challenge/` from a shared webroot and redirects every other path to HTTPS. `GET /healthz` returns `ok` on both listeners.

**Let's Encrypt mode.** Profile `letsencrypt` starts `certbot/certbot:v5.8.0`. It renews with the webroot plugin every 12 hours. It does not request the first certificate by itself.

Images: `nginx:1.30.6-alpine`, `certbot/certbot:v5.8.0`.

## Demo

From the pack root:

```bash
make demo
```

Or from this folder:

```bash
./scripts/gen-self-signed.sh
docker compose up -d
curl -k https://localhost:8443
```

The page body contains `compose-templates-nginx-ok`.

## Let's Encrypt

Point `CERTBOT_DOMAIN` at a name that resolves to this host, and open port 80. The email in `.env.example` is `admin@example.com`. Change both before you issue a real certificate.

```bash
cp .env.example .env
# edit CERTBOT_DOMAIN and CERTBOT_EMAIL
./scripts/issue-cert.sh
docker compose --profile letsencrypt up -d
```

`scripts/issue-cert.sh` runs `certbot certonly --webroot`, copies the lineage into `certs/` with `scripts/export-certs.sh`, and reloads nginx. The certbot service keeps running `certbot renew` and refreshes the files in `certs/`. Reload nginx after a renewal so the new files are used:

```bash
docker compose exec nginx nginx -s reload
```

## Ports

| Host port | Container | Purpose |
| --- | --- | --- |
| `HTTP_PORT` (8080) | 80 | ACME webroot and redirect to HTTPS |
| `HTTPS_PORT` (8443) | 443 | TLS reverse proxy |

Set `HTTPS_PORT` in `.env` if you change the published HTTPS port. The redirect uses that value.

## 中文说明

默认是演示模式。脚本生成 localhost 自签证书。backend 占用网络命名空间并发布端口，nginx 加入同一命名空间，把请求反代到 `127.0.0.1:8081`。页面在 `https://localhost:8443`，正文包含 `compose-templates-nginx-ok`。80 端口只做 ACME webroot 和跳转。

Let's Encrypt 使用 profile `letsencrypt`。`scripts/issue-cert.sh` 用 webroot 申请证书，续期容器每 12 小时执行 `certbot renew`，把证书拷回 `certs/`。续期后需要 `nginx -s reload`。域名和邮箱见 `.env.example`，默认是 `example.com` 和 `admin@example.com`。
