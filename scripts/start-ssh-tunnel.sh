#!/bin/bash

# Description: Provisions an OCI Bastion session and establishes a background SSH tunnel 
# (localhost:2201). This is primarily used to connect to the cloud server using the IDE's 
# Remote-SSH feature. It outputs the tunnel PID so it can be manually killed later.
#
# Run: source ./scripts/start-ssh-tunnel.sh

pwd

source .env

cd terraform/start-ssh-session/

. ../../.env && terraform apply \
-var "tenancy_ocid=$OCI_TENANCY_OCID" \
-var "user_ocid=$OCI_USER_OCID" \
-var "oci_private_key_content=$OCI_PRIVATE_KEY_CONTENT" \
-var "oci_private_key_fingerprint=$OCI_FINGERPRINT" \
-var "region=$OCI_REGION" \
-var "compartment_id=$OCI_COMPARTMENT_ID" \
-var "bastion_public_key_content=$BASTION_PUBLIC_KEY_CONTENT" \
-var "domain=$DOMAIN" \
--auto-approve

export BASTION_SESSION_ID=$(terraform output -raw bastion_connection_session_id)

cd -

echo "Starting SSH tunnel to OCI Bastion in the background..."
ssh -i ./.secret/id_rsa_cloud -N -L 2201:10.1.10.10:22 -p 22 "$BASTION_SESSION_ID@host.bastion.sa-vinhedo-1.oci.oraclecloud.com" &
TUNNEL_PID=$!

echo "========================================================"
echo "Tunnel successfully established in the background!"
echo "Tunnel PID: $TUNNEL_PID"
echo "You can now connect using your IDE's Remote-SSH."
echo "To close the tunnel when you're done, run:"
echo "kill $TUNNEL_PID"
echo "========================================================"
