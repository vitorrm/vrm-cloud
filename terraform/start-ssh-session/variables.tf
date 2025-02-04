variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "oci_private_key_path" {}
variable "fingerprint" {}
variable "region" {}
variable "compartment_id" {}
variable "bastion_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}
