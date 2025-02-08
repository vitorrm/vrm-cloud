#!/bin/bash
# Env vars needed:
# DOMAIN
# SUBDOMAINS
# DUCKDNS_TOKEN
# ADMIN_EMAIL
# OCI_VAULT_ID: grab it from output of terraform infra
# OCI_KMS_SSL_KEY_ID: grab it from output of terraform infra

# # For running local:
# source ../.env

# # Install acme.sh
if ! command -v $HOME/.acme.sh/acme.sh &>/dev/null; then
  echo "Installing acme.sh..."
  curl https://get.acme.sh | sh -s email="$ADMIN_EMAIL"
fi

# # Generate certificate with DuckDNS DNS-01 challenge
export DuckDNS_Token="$DUCKDNS_TOKEN"
$HOME/.acme.sh/acme.sh --issue --dns dns_duckdns -d "${SUBDOMAINS}" -d "${SUBDOMAINS}"

# Paths to certificate files
CERT_DIR="$HOME/.acme.sh/${SUBDOMAINS}_ecc"
PRIVKEY_FILE="$CERT_DIR/${SUBDOMAINS}.key"
CA_FILE="$CERT_DIR/ca.cer"
FULLCHAIN_FILE="$CERT_DIR/fullchain.cer"

export BASE64_PRIVKEY=$(echo "$(cat "$PRIVKEY_FILE")" | base64 -w 0)
export BASE64_CA=$(echo "$(cat "$CA_FILE")" | base64 -w 0)
export BASE64_FULLCHAIN=$(echo "$(cat "$FULLCHAIN_FILE")" | base64 -w 0)
echo "BASE64_PRIVKEY=$BASE64_PRIVKEY" >> "$GITHUB_ENV"
echo "BASE64_CA=$BASE64_CA" >> "$GITHUB_ENV"
echo "BASE64_PRIVKEY=$BASE64_FULLCHAIN" >> "$GITHUB_ENV"
echo "::add-mask::$BASE64_PRIVKEY"
echo "::add-mask::$BASE64_CA"
echo "::add-mask::$BASE64_FULLCHAIN"
