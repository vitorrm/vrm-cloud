resource "oci_core_instance" "vrm_cloud_server" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domain.ad.name
  shape               = "VM.Standard.A1.Flex"
  display_name        = "vrm-cloud-server"

  shape_config {
    ocpus         = 4  # Free Tier allows up to 4 ARM cores total
    memory_in_gbs = 24 # 24GB RAM
  }

  source_details {
    source_id   = data.oci_core_images.arm_images.images[0].id
    source_type = "image"
  }

  create_vnic_details {
    private_ip                = "10.1.10.10"
    hostname_label            = "vrmcloudserver"
    assign_private_dns_record = true
    assign_public_ip          = false
    subnet_id                 = oci_core_subnet.private_subnet.id
  }

  metadata = {
    ssh_authorized_keys = var.bastion_public_key_content
  }

  agent_config {
    plugins_config {
      desired_state = "ENABLED"
      name          = "Bastion"
    }
  }

  # # NOTE: ignore changes to image and authorized_keys, these will get updated out of band
  # lifecycle {
  #   ignore_changes = ["image", "metadata"]
  # }
}
