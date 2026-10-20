#!/bin/sh
# Copy an issued Let's Encrypt lineage into ./certs for nginx.
set -eu
cd "$(dirname "$0")/.." || exit 1
domain="${CERTBOT_DOMAIN:-example.com}"
src="letsencrypt/live/${domain}"
if [ ! -e "${src}/fullchain.pem" ] || [ ! -e "${src}/privkey.pem" ]; then
  echo "no issued certificate at ${src}" >&2
  exit 1
fi
cp -L "${src}/fullchain.pem" certs/fullchain.pem
cp -L "${src}/privkey.pem" certs/privkey.pem
chmod 644 certs/fullchain.pem
chmod 600 certs/privkey.pem
echo "exported ${domain} into certs/"
