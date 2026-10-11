#!/bin/bash
set -euo pipefail

# Env vars needed:
# DOMAIN
# SUBDOMAINS (optional, e.g. *.domain.duckdns.org)
# DUCKDNS_TOKEN
# ADMIN_EMAIL

# For running local:
if [ -f "../.env" ]; then
  source ../.env
elif [ -f ".env" ]; then
  source .env
fi

if [ -z "${DOMAIN:-}" ]; then
  echo "Error: DOMAIN environment variable is required." >&2
  exit 1
fi

if [ -z "${DUCKDNS_TOKEN:-}" ]; then
  echo "Error: DUCKDNS_TOKEN environment variable is required." >&2
  exit 1
fi

ADMIN_EMAIL="${ADMIN_EMAIL:-admin@${DOMAIN}}"
CERTS_DIR="${CERTS_DIR:-certs}"
mkdir -p "$CERTS_DIR"

ACME_HOME="$HOME/.acme.sh"
ACME_BIN="$ACME_HOME/acme.sh"

# Install acme.sh if not installed
if ! command -v "$ACME_BIN" &>/dev/null; then
  echo "Installing acme.sh..."
  curl -s https://get.acme.sh | sh -s email="$ADMIN_EMAIL"
fi

# Set DuckDNS token for acme.sh dns_duckdns hook
export DuckDNS_Token="$DUCKDNS_TOKEN"

# Build domain arguments
DOMAIN_ARGS=("-d" "$DOMAIN")
if [ -n "${SUBDOMAINS:-}" ] && [ "$SUBDOMAINS" != "$DOMAIN" ]; then
  DOMAIN_ARGS+=("-d" "$SUBDOMAINS")
fi

echo "Requesting certificate for: ${DOMAIN_ARGS[*]}"

# Generate or renew certificate
# If cert already exists in acme.sh, attempt renewal
if [ -d "$ACME_HOME/${DOMAIN}_ecc" ] || [ -d "$ACME_HOME/${DOMAIN}" ]; then
  echo "Existing certificate found in ~/.acme.sh. Checking/renewing..."
  "$ACME_BIN" --renew --dns dns_duckdns "${DOMAIN_ARGS[@]}" || echo "Certificate is still valid or renewal skipped."
else
  echo "Issuing new certificate..."
  "$ACME_BIN" --issue --dns dns_duckdns "${DOMAIN_ARGS[@]}"
fi

# Install certificate files into target directory
echo "Exporting certificate files to $CERTS_DIR..."
if ! "$ACME_BIN" --install-cert -d "$DOMAIN" --ecc \
  --key-file "$CERTS_DIR/privkey.pem" \
  --fullchain-file "$CERTS_DIR/fullchain.pem" \
  --ca-file "$CERTS_DIR/ca.pem"; then
  echo "ECC install failed, trying standard install..."
  "$ACME_BIN" --install-cert -d "$DOMAIN" \
    --key-file "$CERTS_DIR/privkey.pem" \
    --fullchain-file "$CERTS_DIR/fullchain.pem" \
    --ca-file "$CERTS_DIR/ca.pem"
fi

PRIVKEY_FILE="$CERTS_DIR/privkey.pem"
FULLCHAIN_FILE="$CERTS_DIR/fullchain.pem"
CA_FILE="$CERTS_DIR/ca.pem"

if [ ! -s "$PRIVKEY_FILE" ] || [ ! -s "$FULLCHAIN_FILE" ]; then
  echo "Error: Certificate generation or installation failed. Files missing in $CERTS_DIR." >&2
  exit 1
fi

# Create CA file if empty from fullchain
if [ ! -s "$CA_FILE" ]; then
  cp "$FULLCHAIN_FILE" "$CA_FILE"
fi

BASE64_PRIVKEY=$(base64 -w 0 < "$PRIVKEY_FILE")
BASE64_CA=$(base64 -w 0 < "$CA_FILE")
BASE64_FULLCHAIN=$(base64 -w 0 < "$FULLCHAIN_FILE")

# Export to GitHub Actions environment if present
if [ -n "${GITHUB_ENV:-}" ]; then
  echo "BASE64_PRIVKEY=$BASE64_PRIVKEY" >> "$GITHUB_ENV"
  echo "BASE64_CA=$BASE64_CA" >> "$GITHUB_ENV"
  echo "BASE64_FULLCHAIN=$BASE64_FULLCHAIN" >> "$GITHUB_ENV"
  echo "CERTS_DIR=$CERTS_DIR" >> "$GITHUB_ENV"
  echo "::add-mask::$BASE64_PRIVKEY"
fi

echo "Certificate generation and export completed successfully."

