#!/bin/bash
set -euo pipefail

# Script to deploy certificates to Oracle Cloud Infrastructure (OCI) Load Balancer
# and synchronize them into OCI Key Vault secrets.

# Local environment loading
if [ -f "../.env" ]; then
  source ../.env
elif [ -f ".env" ]; then
  source .env
fi

# Ensure OCI CLI is available
if ! command -v oci &>/dev/null; then
  echo "Error: OCI CLI is not installed or not in PATH." >&2
  exit 1
fi

if [ -z "${OCI_COMPARTMENT_ID:-}" ]; then
  echo "Error: OCI_COMPARTMENT_ID environment variable is required." >&2
  exit 1
fi

CERTS_DIR="${CERTS_DIR:-certs}"
PRIVKEY_FILE="$CERTS_DIR/privkey.pem"
FULLCHAIN_FILE="$CERTS_DIR/fullchain.pem"
CA_FILE="$CERTS_DIR/ca.pem"

if [ ! -s "$PRIVKEY_FILE" ] || [ ! -s "$FULLCHAIN_FILE" ]; then
  echo "Error: Certificate files not found in $CERTS_DIR. Make sure generate-cert.sh ran successfully." >&2
  exit 1
fi

# -----------------------------------------------------------------------------
# 1. Locate OCI Load Balancer
# -----------------------------------------------------------------------------
LB_ID="${OCI_LB_ID:-}"
if [ -z "$LB_ID" ]; then
  echo "OCI_LB_ID not provided. Discovering load balancer in compartment..."
  # Try to find load balancer by name 'vrm_load_balancer' first
  LB_ID=$(oci lb load-balancer list \
    --compartment-id "$OCI_COMPARTMENT_ID" \
    --lifecycle-state ACTIVE \
    --query "data[?\"display-name\"=='vrm_load_balancer'].id | [0]" \
    --raw-output 2>/dev/null || echo "")

  # Fallback to first active load balancer in the compartment
  if [ -z "$LB_ID" ] || [ "$LB_ID" = "null" ]; then
    LB_ID=$(oci lb load-balancer list \
      --compartment-id "$OCI_COMPARTMENT_ID" \
      --lifecycle-state ACTIVE \
      --query "data[0].id" \
      --raw-output 2>/dev/null || echo "")
  fi
fi

if [ -z "$LB_ID" ] || [ "$LB_ID" = "null" ]; then
  echo "Error: Could not locate an active OCI Load Balancer in compartment $OCI_COMPARTMENT_ID." >&2
  exit 1
fi

echo "Using Load Balancer OCID: $LB_ID"

# -----------------------------------------------------------------------------
# 2. Deploy Certificate to Load Balancer
# -----------------------------------------------------------------------------
LISTENER_NAME="https-listener"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
NEW_CERT_NAME="duckdns-cert-${TIMESTAMP}"

# Query currently active listener configuration from Load Balancer
LISTENER_JSON=$(oci lb load-balancer get \
  --load-balancer-id "$LB_ID" \
  --query 'data.listeners."https-listener"' \
  2>/dev/null || echo "{}")

OLD_CERT_NAME=$(echo "$LISTENER_JSON" | jq -r '."ssl-configuration"."certificate-name" // empty' 2>/dev/null || echo "")
BACKEND_SET=$(echo "$LISTENER_JSON" | jq -r '."default-backend-set-name" // "backendSet"' 2>/dev/null || echo "backendSet")
PORT=$(echo "$LISTENER_JSON" | jq -r '.port // 443' 2>/dev/null || echo "443")
PROTOCOL=$(echo "$LISTENER_JSON" | jq -r '.protocol // "HTTP"' 2>/dev/null || echo "HTTP")
HOSTNAMES=$(echo "$LISTENER_JSON" | jq -c '."hostname-names" // []' 2>/dev/null || echo "[]")

echo "Current listener certificate: ${OLD_CERT_NAME:-none}"
echo "Uploading new certificate '$NEW_CERT_NAME' to Load Balancer..."

CA_OPT=()
if [ -s "$CA_FILE" ]; then
  CA_OPT=("--ca-certificate-file" "$CA_FILE")
fi

oci lb certificate create \
  --load-balancer-id "$LB_ID" \
  --certificate-name "$NEW_CERT_NAME" \
  --private-key-file "$PRIVKEY_FILE" \
  --public-certificate-file "$FULLCHAIN_FILE" \
  "${CA_OPT[@]}" \
  --wait-for-state SUCCEEDED

echo "Certificate '$NEW_CERT_NAME' successfully created on Load Balancer."

# Build hostname arguments if hostnames exist
HOSTNAME_OPT=()
if [ "$HOSTNAMES" != "[]" ] && [ -n "$HOSTNAMES" ]; then
  HOSTNAME_OPT=("--hostname-names" "$HOSTNAMES")
fi

# Update the listener to use the new certificate
echo "Updating listener '$LISTENER_NAME' to reference '$NEW_CERT_NAME'..."
oci lb listener update \
  --load-balancer-id "$LB_ID" \
  --listener-name "$LISTENER_NAME" \
  --default-backend-set-name "$BACKEND_SET" \
  --port "$PORT" \
  --protocol "$PROTOCOL" \
  --ssl-certificate-name "$NEW_CERT_NAME" \
  --ssl-verify-peer-certificate false \
  "${HOSTNAME_OPT[@]}" \
  --force \
  --wait-for-state SUCCEEDED

echo "Listener '$LISTENER_NAME' successfully updated with '$NEW_CERT_NAME'."

# Clean up previously rotated certificate (if it matches dynamic naming duckdns-cert-*)
if [ -n "$OLD_CERT_NAME" ] && [ "$OLD_CERT_NAME" != "null" ] && [ "$OLD_CERT_NAME" != "$NEW_CERT_NAME" ]; then
  if [[ "$OLD_CERT_NAME" =~ ^duckdns-cert-[0-9]+$ ]]; then
    echo "Deleting superseded certificate '$OLD_CERT_NAME'..."
    oci lb certificate delete \
      --load-balancer-id "$LB_ID" \
      --certificate-name "$OLD_CERT_NAME" \
      --force || echo "Warning: Failed to delete superseded certificate '$OLD_CERT_NAME'."
  fi
fi


# -----------------------------------------------------------------------------
# 3. Synchronize Secrets to OCI Key Vault
# -----------------------------------------------------------------------------
if [ -n "${OCI_VAULT_ID:-}" ] && [ -n "${OCI_KMS_SSL_KEY_ID:-}" ]; then
  echo "Synchronizing certificate secrets to OCI Key Vault..."

  BASE64_PRIVKEY=$(base64 -w 0 < "$PRIVKEY_FILE")
  BASE64_FULLCHAIN=$(base64 -w 0 < "$FULLCHAIN_FILE")
  if [ -s "$CA_FILE" ]; then
    BASE64_CA=$(base64 -w 0 < "$CA_FILE")
  else
    BASE64_CA="$BASE64_FULLCHAIN"
  fi

  sync_vault_secret() {
    local secret_name="$1"
    local base64_content="$2"

    local secret_id
    secret_id=$(oci vault secret list \
      --compartment-id "$OCI_COMPARTMENT_ID" \
      --name "$secret_name" \
      --lifecycle-state ACTIVE \
      --query "data[0].id" \
      --raw-output 2>/dev/null || echo "")

    if [ -z "$secret_id" ] || [ "$secret_id" = "null" ]; then
      echo "Creating Vault secret '$secret_name'..."
      oci vault secret create-base64 \
        --compartment-id "$OCI_COMPARTMENT_ID" \
        --vault-id "$OCI_VAULT_ID" \
        --key-id "$OCI_KMS_SSL_KEY_ID" \
        --secret-name "$secret_name" \
        --secret-content-content "$base64_content"
    else
      echo "Updating Vault secret '$secret_name' ($secret_id)..."
      oci vault secret update-base64 \
        --secret-id "$secret_id" \
        --secret-content-content "$base64_content" \
        --force
    fi
  }

  sync_vault_secret "cert-domain-privkey" "$BASE64_PRIVKEY"
  sync_vault_secret "cert-domain-ca" "$BASE64_CA"
  sync_vault_secret "cert-domain-fullchain" "$BASE64_FULLCHAIN"
  echo "OCI Vault secrets updated successfully."
else
  echo "OCI_VAULT_ID or OCI_KMS_SSL_KEY_ID not set. Skipping Vault sync."
fi

echo "Certificate deployment to Oracle Load Balancer completed successfully!"
