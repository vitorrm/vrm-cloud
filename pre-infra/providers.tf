terraform {
  required_providers {
      oci = {
          source  = "hashicorp/oci"
          version = ">= 6.24.0"
      }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint      = var.fingerprint
  region           = var.region
}