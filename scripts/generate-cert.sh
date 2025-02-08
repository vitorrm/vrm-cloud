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

export BASE64_PRIVKEY=$(echo "TEST CERT" | base64 -w 0)
echo "BASE64_PRIVKEY=$BASE64_PRIVKEY" >> "$GITHUB_ENV"

# # # Install acme.sh
# if ! command -v $HOME/.acme.sh/acme.sh &>/dev/null; then
#   echo "Installing acme.sh..."
#   curl https://get.acme.sh | sh -s email="$ADMIN_EMAIL"
# fi

# # # Generate certificate with DuckDNS DNS-01 challenge
# export DuckDNS_Token="$DUCKDNS_TOKEN"
# $HOME/.acme.sh/acme.sh --issue --dns dns_duckdns -d "${SUBDOMAINS}" -d "${SUBDOMAINS}"

# # Paths to certificate files
# CERT_DIR="$HOME/.acme.sh/${SUBDOMAINS}_ecc"
# PRIVKEY_FILE="$CERT_DIR/${SUBDOMAINS}.key"
# CA_FILE="$CERT_DIR/ca.cer"
# FULLCHAIN_FILE="$CERT_DIR/fullchain.cer"

# export BASE64_PRIVKEY=$(echo "$(cat "$FULLCHAIN_FILE")" | base64 -w 0)
# export BASE64_CA=$(echo "$(cat "$FULLCHAIN_FILE")" | base64 -w 0)
# export BASE64_FULLCHAIN=$(echo "$(cat "$FULLCHAIN_FILE")" | base64 -w 0)

# Function to create/update OCI Vault secrets
upload_to_oci_secrets() {
  local SECRET_NAME="$1"
  local FILE_CONTENT="$2"
  local BASE64_CONTENT=$(echo "$FILE_CONTENT" | base64 -w 0)

  # Check if secret exists
  EXISTING_SECRET=$(oci vault secret list \
    --compartment-id "$OCI_COMPARTMENT_ID" \
    --name "$SECRET_NAME" \
    --region "$OCI_REGION" \
    --query "data[0].id" --raw-output 2>/dev/null || true)

  if [ -n "$EXISTING_SECRET" ]; then
    # Update existing secret
    oci vault secret update-base64 \
      --secret-id "$EXISTING_SECRET" \
      --secret-content-content "$BASE64_CONTENT" \
      --region "$OCI_REGION" \
      --force
    echo "$EXISTING_SECRET"
  else
    # Create new secret
    NEW_SECRET=$(oci vault secret create-base64 \
      --compartment-id "$OCI_COMPARTMENT_ID" \
      --secret-name "$SECRET_NAME" \
      --vault-id "$OCI_VAULT_ID" \
      --key-id "$OCI_KMS_SSL_KEY_ID" \
      --secret-content-content "$BASE64_CONTENT" \
      --region "$OCI_REGION" \
      --query "data.id" --raw-output)
    echo "$NEW_SECRET"
  fi
}