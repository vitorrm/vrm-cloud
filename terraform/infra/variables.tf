variable "region" {}
variable "tenancy_ocid" {
  sensitive = true
}
variable "user_ocid" {
  sensitive = true
}
variable "oci_private_key_path" {
  sensitive = true
}
variable "fingerprint" {
  sensitive = true
}
variable "compartment_id" {
  sensitive = true
}
variable "bastion_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

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
