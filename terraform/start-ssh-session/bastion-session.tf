

data "oci_bastion_bastions" "bastion_list" {
  compartment_id = var.compartment_id
  name           = "vrm_bastion"
}

data "oci_core_instances" "instances_list" {
  compartment_id = var.compartment_id
  display_name   = "vrm-cloud-server"
  state          = "RUNNING"
}

locals {
  bastion_id     = data.oci_bastion_bastions.bastion_list.bastions[0].id
  bastion_target = data.oci_core_instances.instances_list.instances[0]
}

resource "oci_bastion_session" "session_port_forwarding" {
  bastion_id = local.bastion_id

  key_details {
    public_key_content = var.bastion_public_key_content
  }
  target_resource_details {
    session_type = "PORT_FORWARDING"
    // You should either use target_resource_id or target_resource_private_ip_address in port forwarding session
    target_resource_id                 = local.bastion_target.id
    target_resource_private_ip_address = local.bastion_target.private_ip
    target_resource_port               = 22
  }
  display_name           = "vrm_bastion_session_port_forwarding"
  session_ttl_in_seconds = 1800 // 30min
}

data "oci_bastion_sessions" "bastion_sessions_port_forwarding" {
  bastion_id              = local.bastion_id
  display_name            = "vrm_bastion_session_port_forwarding"
  session_id              = oci_bastion_session.session_port_forwarding.id
  session_lifecycle_state = "ACTIVE"
}

output "bastion_connection_details" {
  value = oci_bastion_session.session_port_forwarding.ssh_metadata.command
}

output "bastion_connection_session_id" {
  value = oci_bastion_session.session_port_forwarding.id
}

## MANAGED SESSION
# resource "oci_bastion_session" "session_managed_ssh" {
#   bastion_id = oci_bastion_bastion.vrm_bastion.id
#   key_details {
#     public_key_content = var.bastion_public_key_content
#   }
#   target_resource_details {
#     session_type                               = "MANAGED_SSH"
#     target_resource_id                         = oci_core_instance.vrm_cloud_server.id
#     target_resource_operating_system_user_name = "opc"
#     target_resource_port                       = 22
#     target_resource_private_ip_address         = oci_core_instance.vrm_cloud_server.private_ip
#   }
#   display_name           = "vrm_bastion_session_managed_ssh"
#   session_ttl_in_seconds = 1800 // 30min
# }

# data "oci_bastion_sessions" "bastion_sessions_managed_ssh" {
#   bastion_id              = oci_bastion_bastion.vrm_bastion.id
#   display_name            = "vrm_bastion_session_managed_ssh"
#   session_id              = oci_bastion_session.session_managed_ssh.id
#   session_lifecycle_state = "ACTIVE"
# }

# output "bastion_connection_details_m" {
#   value = oci_bastion_session.session_managed_ssh.ssh_metadata.command
# }



