#!/bin/sh
# Write a localhost certificate into ./certs so nginx can start without Let's Encrypt.
set -eu
cd "$(dirname "$0")/.." || exit 1
mkdir -p certs
if [ -s certs/fullchain.pem ] && [ -s certs/privkey.pem ]; then
  echo "self-signed certificate already present"
  exit 0
fi
cnf="$(mktemp)"
trap 'rm -f "$cnf"' EXIT
cat >"$cnf" <<'EOF'
[req]
distinguished_name = dn
x509_extensions = v3_req
prompt = no
[dn]
CN = localhost
[v3_req]
subjectAltName = DNS:localhost,IP:127.0.0.1
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
EOF
openssl req -x509 -nodes -newkey rsa:2048 -days 30 \
  -keyout certs/privkey.pem \
  -out certs/fullchain.pem \
  -config "$cnf"
chmod 644 certs/fullchain.pem
chmod 600 certs/privkey.pem
echo "wrote certs/fullchain.pem and certs/privkey.pem"
