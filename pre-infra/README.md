# Pre Infra

Just for creating the base resources

## To run

```bash
. ../.env && terraform plan -var "tenancy_ocid=$OCI_TENANCY_OCID" -var "user_ocid=$OCI_USER_OCID" -var "private_key_path=~/.oci/oci_api_key.pem" -var "fingerprint=$OCI_FINGERPRINT" -var "region=$OCI_REGION" -var "compartment_id=$OCI_COMPARTMENT_ID"
```

```bash
. ../.env && terraform apply -var "tenancy_ocid=$OCI_TENANCY_OCID" -var "user_ocid=$OCI_USER_OCID" -var "private_key_path=~/.oci/oci_api_key.pem" -var "fingerprint=$OCI_FINGERPRINT" -var "region=$OCI_REGION" -var "compartment_id=$OCI_COMPARTMENT_ID"
```
