#!/bin/sh
# First Let's Encrypt certificate via the HTTP-01 webroot.
# Requires port 80 on CERTBOT_DOMAIN to reach this nginx.
set -eu
cd "$(dirname "$0")/.." || exit 1
domain="${CERTBOT_DOMAIN:-example.com}"
email="${CERTBOT_EMAIL:-admin@example.com}"
./scripts/gen-self-signed.sh
docker compose up -d backend nginx
docker compose --profile letsencrypt run --rm --no-deps --entrypoint certbot certbot \
  certonly --webroot -w /var/www/certbot \
  --cert-name "$domain" \
  -d "$domain" \
  --email "$email" \
  --agree-tos --no-eff-email --non-interactive
./scripts/export-certs.sh
docker compose exec nginx nginx -s reload
echo "issued certificate for ${domain}"
