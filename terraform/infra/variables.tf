variable "region" {}
variable "tenancy_ocid" {
  sensitive = true
}
variable "user_ocid" {
  sensitive = true
}
variable "oci_private_key_content" {
  sensitive = true
}
variable "oci_private_key_fingerprint" {
  sensitive = true
}
variable "compartment_id" {
  sensitive = true
}
variable "bastion_public_key_content" {
  default = ""
}

variable "domain" {}

# Data source for availability domain
data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

data "oci_objectstorage_namespace" "user_namespace" {}

# See https://docs.oracle.com/iaas/images/
# Data source to get AMD Oracle Linux image
data "oci_core_images" "amd_images" {
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Data source to get ARM Oracle Linux image
data "oci_core_images" "arm_images" {
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_vault_secrets" "secret_domain_privkey" {
  compartment_id = var.compartment_id
  name           = "cert-domain-privkey"
}

data "oci_vault_secrets" "secret_domain_ca" {
  compartment_id = var.compartment_id
  name           = "cert-domain-ca"
}

data "oci_vault_secrets" "secret_domain_fullchain" {
  compartment_id = var.compartment_id
  name           = "cert-domain-fullchain"
}

data "oci_secrets_secretbundle" "secretbundle_domain_privkey" {
  secret_id = data.oci_vault_secrets.secret_domain_privkey.secrets[0].id
}

data "oci_secrets_secretbundle" "secretbundle_domain_ca" {
  secret_id = data.oci_vault_secrets.secret_domain_ca.secrets[0].id
}

data "oci_secrets_secretbundle" "secretbundle_domain_fullchain" {
  secret_id = data.oci_vault_secrets.secret_domain_fullchain.secrets[0].id
}
