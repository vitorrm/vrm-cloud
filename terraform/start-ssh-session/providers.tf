
terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.23.0"
    }
  }
}

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
  private_key  = var.oci_private_key_content
  fingerprint  = var.oci_private_key_fingerprint
  region       = var.region
}
