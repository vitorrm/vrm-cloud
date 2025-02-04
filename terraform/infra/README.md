# Infra

Creates infra resources

## To init

```bash
terraform init -backend-config="./backend.config"
```

## To run

```bash
. ../../.env && terraform plan -var "tenancy_ocid=$OCI_TENANCY_OCID" -var "user_ocid=$OCI_USER_OCID" -var "oci_private_key_path=~/.oci/oci_api_key.pem" -var "fingerprint=$OCI_FINGERPRINT" -var "region=$OCI_REGION" -var "compartment_id=$OCI_COMPARTMENT_ID" -var "bastion_public_key_content=$BASTION_PUBLIC_KEY_CONTENT" -auto-approve
```

```bash
. ../../.env && terraform apply -var "tenancy_ocid=$OCI_TENANCY_OCID" -var "user_ocid=$OCI_USER_OCID" -var "oci_private_key_path=~/.oci/oci_api_key.pem" -var "fingerprint=$OCI_FINGERPRINT" -var "region=$OCI_REGION" -var "compartment_id=$OCI_COMPARTMENT_ID" -var "bastion_public_key_content=$BASTION_PUBLIC_KEY_CONTENT" -auto-approve
```

## Respources

https://medium.com/@williamwarley/oracle-cloud-infrastructure-oci-vcn-and-security-layers-with-terraform-8891b28c3d2d
