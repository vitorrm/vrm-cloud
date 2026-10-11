#!/bin/bash

# Description: Provisions an OCI Bastion session, establishes an SSH tunnel in the background, 
# and drops you into an interactive terminal session to the cloud server. The tunnel is 
# automatically closed when you exit the SSH session.
#
# Run: source ./scripts/ssh-into-cloud.sh

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

echo "Starting SSH tunnel to OCI Bastion..."
ssh -i ./.secret/id_rsa_cloud -N -L 2201:10.1.10.10:22 -p 22 "$BASTION_SESSION_ID@host.bastion.sa-vinhedo-1.oci.oraclecloud.com" &
TUNNEL_PID=$!  # Captures the Process ID of the background command

echo "Waiting for the tunnel to establish..."
sleep 3  # Gives the tunnel time to bind to port 2201

echo "Connecting to target instance..."
ssh -i ./.secret/id_rsa_cloud ubuntu@localhost -p 2201

# This runs only AFTER you type 'exit' or disconnect from the ubuntu session
echo "Closing background SSH tunnel (PID: $TUNNEL_PID)..."
kill $TUNNEL_PID