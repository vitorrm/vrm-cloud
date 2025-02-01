
terraform {
  backend "http" {
    address = ""
    update_method = "PUT"
  }
  required_providers {
      oci = {
          source  = "oracle/oci"
          version = ">= 6.23.0"
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