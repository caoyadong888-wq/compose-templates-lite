# Test results

Date: 2026-10-20T02:53:56Z

## Tool versions

```
date 2026-10-20T02:53:38Z
docker client 26.1.5+dfsg1 server 26.1.5+dfsg1
Docker Compose version v2.29.7
Python 3.13.5
OpenSSL 3.5.7 9 Jun 2026 (Library: OpenSSL 3.5.7 9 Jun 2026)
curl 8.14.1 (x86_64-pc-linux-gnu) libcurl/8.14.1 OpenSSL/3.5.7 zlib/1.3.1 brotli/1.1.0 zstd/1.5.7 libidn2/2.3.8 libpsl/0.21.2 libssh2/1.11.1 nghttp2/1.64.0 nghttp3/1.8.0 librtmp/2.3 OpenLDAP/2.6.10
ShellCheck - shell script analysis tool
version: 0.11.0
license: GNU General Public License, version 3
website: https://www.shellcheck.net
```

## Checks

```
Root: demo-host pack compose-templates-lite
PASS: docker compose config 01-nginx-https
PASS: docker compose config 01-nginx-https profile letsencrypt
PASS: docker compose config 02-postgres
PASS: compose files pin image tags
PASS: shellcheck
PASS: make demo curls https://localhost:8443
PASS: 01 nginx https health
PASS: 02 postgres up
PASS: 02 pg_isready
PASS: 02 backup command
PASS: 02 backup dump exists
PASS: cleanup down -v
failures: 0
```

## Command output

```

===== docker compose config 01-nginx-https =====
name: ct-nginx-https
services:
  backend:
    healthcheck:
      test:
        - CMD
        - wget
        - -q
        - -O
        - /dev/null
        - http://127.0.0.1:8081/
      timeout: 3s
      interval: 5s
      retries: 12
      start_period: 3s
    image: nginx:1.30.6-alpine
    networks:
      default: null
    ports:
      - mode: ingress
        target: 80
        published: "8080"
        protocol: tcp
      - mode: ingress
        target: 443
        published: "8443"
        protocol: tcp
    restart: unless-stopped
    volumes:
      - type: bind
        source: /workspace/products/compose-templates/lite/01-nginx-https/www
        target: /usr/share/nginx/html
        read_only: true
        bind:
          create_host_path: true
      - type: bind
        source: /workspace/products/compose-templates/lite/01-nginx-https/backend/default.conf
        target: /etc/nginx/conf.d/default.conf
        read_only: true
        bind:
          create_host_path: true
  nginx:
    depends_on:
      backend:
        condition: service_healthy
        required: true
    environment:
      HTTPS_PORT: "8443"
      NGINX_ENVSUBST_OUTPUT_DIR: /etc/nginx
      NGINX_ENVSUBST_TEMPLATE_DIR: /etc/nginx/templates
    healthcheck:
      test:
        - CMD
        - wget
        - -q
        - -O
        - /dev/null
        - http://127.0.0.1/healthz
      timeout: 3s
      interval: 5s
      retries: 12
      start_period: 5s
    image: nginx:1.30.6-alpine
    network_mode: service:backend
    restart: unless-stopped
    volumes:
      - type: bind
        source: /workspace/products/compose-templates/lite/01-nginx-https/nginx/nginx.conf.template
        target: /etc/nginx/templates/nginx.conf.template
        read_only: true
        bind:
          create_host_path: true
      - type: bind
        source: /workspace/products/compose-templates/lite/01-nginx-https/certs
        target: /etc/nginx/certs
        read_only: true
        bind:
          create_host_path: true
      - type: volume
        source: webroot
        target: /var/www/certbot
        volume: {}
networks:
  default:
    name: ct-nginx-https_default
volumes:
  webroot:
    name: ct-nginx-https_webroot

===== docker compose config 01-nginx-https profile letsencrypt =====
name: ct-nginx-https
services:
  backend:
    healthcheck:
      test:
        - CMD
        - wget
        - -q
        - -O
        - /dev/null
        - http://127.0.0.1:8081/
      timeout: 3s
      interval: 5s
      retries: 12
      start_period: 3s
    image: nginx:1.30.6-alpine
    networks:
      default: null
    ports:
      - mode: ingress
        target: 80
        published: "8080"
        protocol: tcp
      - mode: ingress
        target: 443
        published: "8443"
        protocol: tcp
    restart: unless-stopped
    volumes:
      - type: bind
        source: /workspace/products/compose-templates/lite/01-nginx-https/www
        target: /usr/share/nginx/html
        read_only: true
        bind:
          create_host_path: true
      - type: bind
        source: /workspace/products/compose-templates/lite/01-nginx-https/backend/default.conf
        target: /etc/nginx/conf.d/default.conf
        read_only: true
        bind:
          create_host_path: true
  certbot:
    profiles:
      - letsencrypt
    depends_on:
      nginx:
        condition: service_started
        required: true
    entrypoint:
      - /bin/sh
      - /scripts/renew-loop.sh
    environment:
      CERTBOT_DOMAIN: example.com
      CERTBOT_EMAIL: admin@example.com
    image: certbot/certbot:v5.8.0
    networks:
      default: null
    restart: unless-stopped
    volumes:
      - type: bind
        source: /workspace/products/compose-templates/lite/01-nginx-https/scripts/renew-loop.sh
        target: /scripts/renew-loop.sh
        read_only: true
        bind:
          create_host_path: true
      - type: volume
        source: webroot
        target: /var/www/certbot
        volume: {}
      - type: bind
        source: /workspace/products/compose-templates/lite/01-nginx-https/letsencrypt
        target: /etc/letsencrypt
        bind:
          create_host_path: true
      - type: bind
        source: /workspace/products/compose-templates/lite/01-nginx-https/certs
        target: /certs
        bind:
          create_host_path: true
  nginx:
    depends_on:
      backend:
        condition: service_healthy
        required: true
    environment:
      HTTPS_PORT: "8443"
      NGINX_ENVSUBST_OUTPUT_DIR: /etc/nginx
      NGINX_ENVSUBST_TEMPLATE_DIR: /etc/nginx/templates
    healthcheck:
      test:
        - CMD
        - wget
        - -q
        - -O
        - /dev/null
        - http://127.0.0.1/healthz
      timeout: 3s
      interval: 5s
      retries: 12
      start_period: 5s
    image: nginx:1.30.6-alpine
    network_mode: service:backend
    restart: unless-stopped
    volumes:
      - type: bind
        source: /workspace/products/compose-templates/lite/01-nginx-https/nginx/nginx.conf.template
        target: /etc/nginx/templates/nginx.conf.template
        read_only: true
        bind:
          create_host_path: true
      - type: bind
        source: /workspace/products/compose-templates/lite/01-nginx-https/certs
        target: /etc/nginx/certs
        read_only: true
        bind:
          create_host_path: true
      - type: volume
        source: webroot
        target: /var/www/certbot
        volume: {}
networks:
  default:
    name: ct-nginx-https_default
volumes:
  webroot:
    name: ct-nginx-https_webroot

===== docker compose config 02-postgres =====
name: ct-postgres
services:
  backup:
    depends_on:
      postgres:
        condition: service_healthy
        required: true
    entrypoint:
      - /bin/sh
      - /scripts/backup-loop.sh
    environment:
      BACKUP_INTERVAL_SECONDS: "86400"
      PGDATABASE: app
      PGHOST: 127.0.0.1
      PGPASSWORD: change-me-now
      PGUSER: app
      RETENTION_DAYS: "7"
    image: postgres:16.15-alpine
    network_mode: service:postgres
    restart: unless-stopped
    volumes:
      - type: bind
        source: /workspace/products/compose-templates/lite/02-postgres/backups
        target: /backups
        bind:
          create_host_path: true
      - type: bind
        source: /workspace/products/compose-templates/lite/02-postgres/scripts/backup-once.sh
        target: /scripts/backup-once.sh
        read_only: true
        bind:
          create_host_path: true
      - type: bind
        source: /workspace/products/compose-templates/lite/02-postgres/scripts/backup-loop.sh
        target: /scripts/backup-loop.sh
        read_only: true
        bind:
          create_host_path: true
  postgres:
    environment:
      POSTGRES_DB: app
      POSTGRES_PASSWORD: change-me-now
      POSTGRES_USER: app
    healthcheck:
      test:
        - CMD-SHELL
        - pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB
      timeout: 5s
      interval: 5s
      retries: 12
      start_period: 10s
    image: postgres:16.15-alpine
    networks:
      default: null
    ports:
      - mode: ingress
        target: 5432
        published: "5432"
        protocol: tcp
    restart: unless-stopped
    volumes:
      - type: volume
        source: pgdata
        target: /var/lib/postgresql/data
        volume: {}
      - type: bind
        source: /workspace/products/compose-templates/lite/02-postgres/initdb
        target: /docker-entrypoint-initdb.d
        read_only: true
        bind:
          create_host_path: true
networks:
  default:
    name: ct-postgres_default
volumes:
  pgdata:
    name: ct-postgres_pgdata

===== shellcheck =====
 Volume ct-nginx-https_webroot  Removing
 Volume ct-nginx-https_webroot  Removed
./demo.sh
..+.....+...+....+........+.........+.+..+++++++++++++++++++++++++++++++++++++++*....+...+..........+..+.+.....+.............+++++++++++++++++++++++++++++++++++++++*.....+.+.....+...+....+...............+........+.......+...........+.+........+.+......+.....+.+........+.+...+..+......+....+.....+.+...+..+.......+.....+.......+.........+..+...+..........+..+..........+..++++++
...+...+.+...+++++++++++++++++++++++++++++++++++++++*...+.........+....+..+....+...+......+.....+++++++++++++++++++++++++++++++++++++++*.....+...+....+..................+.....+......+......+....+.....+.........+..........+.....+.......+.....+.+...+.....+..........+...........+...+.+..+...............+....++++++
-----
wrote certs/fullchain.pem and certs/privkey.pem
 Network ct-nginx-https_default  Creating
 Network ct-nginx-https_default  Created
 Volume "ct-nginx-https_webroot"  Creating
 Volume "ct-nginx-https_webroot"  Created
 Container ct-nginx-https-backend-1  Creating
 Container ct-nginx-https-backend-1  Created
 Container ct-nginx-https-nginx-1  Creating
 Container ct-nginx-https-nginx-1  Created
 Container ct-nginx-https-backend-1  Starting
 Container ct-nginx-https-backend-1  Started
 Container ct-nginx-https-backend-1  Waiting
 Container ct-nginx-https-backend-1  Healthy
 Container ct-nginx-https-nginx-1  Starting
 Container ct-nginx-https-nginx-1  Started
curl: (35) Send failure: Broken pipe
+ curl -k https://localhost:8443
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Nginx HTTPS demo</title>
</head>
<body>
  <h1>Nginx HTTPS demo</h1>
  <p>compose-templates-nginx-ok</p>
  <p>This page is served by the backend container through the TLS reverse proxy.</p>
</body>
</html>

Demo is up at https://localhost:8443
Stop it with: make demo-down
 Container ct-nginx-https-nginx-1  Stopping
 Container ct-nginx-https-nginx-1  Stopped
 Container ct-nginx-https-nginx-1  Removing
 Container ct-nginx-https-nginx-1  Removed
 Container ct-nginx-https-backend-1  Stopping
 Container ct-nginx-https-backend-1  Stopped
 Container ct-nginx-https-backend-1  Removing
 Container ct-nginx-https-backend-1  Removed
 Volume ct-nginx-https_webroot  Removing
 Volume ct-nginx-https_webroot  Removed
 Network ct-nginx-https_default  Removing
 Network ct-nginx-https_default  Removed
 Volume ct-postgres_pgdata  Removing
 Volume ct-postgres_pgdata  Removed

===== 02 up =====
 Network ct-postgres_default  Creating
 Network ct-postgres_default  Created
 Volume "ct-postgres_pgdata"  Creating
 Volume "ct-postgres_pgdata"  Created
 Container ct-postgres-postgres-1  Creating
 Container ct-postgres-postgres-1  Created
 Container ct-postgres-backup-1  Creating
 Container ct-postgres-backup-1  Created
 Container ct-postgres-postgres-1  Starting
 Container ct-postgres-postgres-1  Started
 Container ct-postgres-postgres-1  Waiting
 Container ct-postgres-postgres-1  Healthy
 Container ct-postgres-backup-1  Starting
 Container ct-postgres-backup-1  Started
/var/run/postgresql:5432 - accepting connections
backup wrote /backups/app-20261020T025355Z.dump
dump file app-20261020T025355Z.dump size 1607
 Container ct-postgres-backup-1  Stopping
 Container ct-postgres-backup-1  Stopped
 Container ct-postgres-backup-1  Removing
 Container ct-postgres-backup-1  Removed
 Container ct-postgres-postgres-1  Stopping
 Container ct-postgres-postgres-1  Stopped
 Container ct-postgres-postgres-1  Removing
 Container ct-postgres-postgres-1  Removed
 Volume ct-postgres_pgdata  Removing
 Network ct-postgres_default  Removing
 Volume ct-postgres_pgdata  Removed
 Network ct-postgres_default  Removed
 Volume ct-nginx-https_webroot  Removing
 Volume ct-nginx-https_webroot  Removed
 Volume ct-postgres_pgdata  Removing
 Volume ct-postgres_pgdata  Removed
```
