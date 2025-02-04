resource "oci_bastion_bastion" "vrm_bastion" {
  name             = "vrm_bastion"
  bastion_type     = "STANDARD"
  compartment_id   = var.compartment_id
  target_subnet_id = oci_core_subnet.private_subnet.id
  client_cidr_block_allow_list = [
    "0.0.0.0/0"
  ]
  max_session_ttl_in_seconds = 1800
}

output "bastion_id" {
  value = oci_bastion_bastion.vrm_bastion.id
}
