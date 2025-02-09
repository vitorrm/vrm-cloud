#!/bin/bash

#Run: source ./scripts/start-ssh-session.sh

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

