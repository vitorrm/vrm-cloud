
#########
# Volume
#########
resource "oci_core_volume" "extra_volume" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_id
  display_name        = "extra-volume"
  size_in_gbs = "100"
}

####################
# Volume Attachment
####################
# resource "oci_core_volume_attachment" "extra_volume_attachment" {
#   attachment_type = "paravirtualized"
#   instance_id     = oci_core_instance.vrm_cloud_server.id
#   volume_id       = oci_core_volume.extra_volume.id
# }