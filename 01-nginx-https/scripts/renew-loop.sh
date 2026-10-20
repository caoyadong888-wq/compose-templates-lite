#!/bin/sh
# Certbot webroot renewal loop. Does not request the first certificate.
set -eu
domain="${CERTBOT_DOMAIN:-example.com}"
while true; do
  if ! certbot renew --webroot -w /var/www/certbot --quiet; then
    echo "certbot renew failed" >&2
  fi
  if [ -f "/etc/letsencrypt/live/${domain}/fullchain.pem" ]; then
    cp -L "/etc/letsencrypt/live/${domain}/fullchain.pem" /certs/fullchain.pem
    cp -L "/etc/letsencrypt/live/${domain}/privkey.pem" /certs/privkey.pem
    chmod 644 /certs/fullchain.pem
    chmod 600 /certs/privkey.pem
  fi
  sleep 43200 &
  wait "$!"
done
