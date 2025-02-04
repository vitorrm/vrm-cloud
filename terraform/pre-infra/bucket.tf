# Fetch the namespace of your tenancy (required for buckets)
data "oci_objectstorage_namespace" "user_namespace" {}

# Create the Object Storage bucket
resource "oci_objectstorage_bucket" "terraform_state_bucket" {
  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.user_namespace.namespace
  name           = "terraform-state"
  access_type    = "NoPublicAccess"
}