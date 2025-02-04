# Pre Infra

Just for creating the bucket for storing the terraform infra state

## To run

```bash
. ../../.env && terraform plan \
-var "tenancy_ocid=$OCI_TENANCY_OCID" \
-var "user_ocid=$OCI_USER_OCID" \
-var "oci_private_key_content=$OCI_PRIVATE_KEY_CONTENT" \
-var "oci_private_key_fingerprint=$OCI_FINGERPRINT" \
-var "region=$OCI_REGION" \
-var "compartment_id=$OCI_COMPARTMENT_ID" \
-var "bastion_public_key_content=$BASTION_PUBLIC_KEY_CONTENT"
```

```bash
. ../../.env && terraform apply \
-var "tenancy_ocid=$OCI_TENANCY_OCID" \
-var "user_ocid=$OCI_USER_OCID" \
-var "oci_private_key_content=$OCI_PRIVATE_KEY_CONTENT" \
-var "oci_private_key_fingerprint=$OCI_FINGERPRINT" \
-var "region=$OCI_REGION" \
-var "compartment_id=$OCI_COMPARTMENT_ID" \
-var "bastion_public_key_content=$BASTION_PUBLIC_KEY_CONTENT" \
--auto-approve
```
