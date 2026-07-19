#!/bin/bash
set -euo pipefail

# Env vars needed:
# DOMAIN
# SUBDOMAINS
# DUCKDNS_TOKEN
# ADMIN_EMAIL
# OCI_VAULT_ID: grab it from output of terraform infra
# OCI_KMS_SSL_KEY_ID: grab it from output of terraform infra

# # For running local:
if [ -f "../.env" ]; then
  source ../.env
fi

# # Install acme.sh
if ! command -v $HOME/.acme.sh/acme.sh &>/dev/null; then
  echo "Installing acme.sh..."
  curl https://get.acme.sh | sh -s email="$ADMIN_EMAIL"
fi

# # Generate certificate with DuckDNS DNS-01 challenge
export DuckDNS_Token="$DUCKDNS_TOKEN"
# Generate or renew certificate
if [ -d "$HOME/.acme.sh/${SUBDOMAINS}_ecc" ]; then
  echo "Certificate directory exists. Attempting renewal..."
  $HOME/.acme.sh/acme.sh --renew --dns dns_duckdns -d "${SUBDOMAINS}" --force || echo "Renewal skipped or failed, using existing certificate."
else
  echo "Issuing new certificate..."
  $HOME/.acme.sh/acme.sh --issue --dns dns_duckdns -d "${SUBDOMAINS}"
fi

# Paths to certificate files
CERT_DIR="$HOME/.acme.sh/${SUBDOMAINS}_ecc"
PRIVKEY_FILE="$CERT_DIR/${SUBDOMAINS}.key"
CA_FILE="$CERT_DIR/ca.cer"
FULLCHAIN_FILE="$CERT_DIR/fullchain.cer"

BASE64_PRIVKEY=$(base64 -w 0 < "$PRIVKEY_FILE")
BASE64_CA=$(base64 -w 0 < "$CA_FILE")
BASE64_FULLCHAIN=$(base64 -w 0 < "$FULLCHAIN_FILE")
echo "BASE64_PRIVKEY=$BASE64_PRIVKEY" >> "$GITHUB_ENV"
echo "BASE64_CA=$BASE64_CA" >> "$GITHUB_ENV"
echo "BASE64_FULLCHAIN=$BASE64_FULLCHAIN" >> "$GITHUB_ENV"
echo "::add-mask::$BASE64_PRIVKEY"
echo "::add-mask::$BASE64_CA"
echo "::add-mask::$BASE64_FULLCHAIN"
