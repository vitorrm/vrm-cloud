# Create a Vault
resource "oci_kms_vault" "ssl_vault" {
  compartment_id = var.compartment_id
  display_name   = "ssl-cert-vault"
  vault_type     = "DEFAULT"
}

# Create a KMS Master Encryption Key for the Vault
resource "oci_kms_key" "kms_ssl_key" {
  compartment_id      = var.compartment_id
  display_name        = "ssl-cert-key"
  management_endpoint = oci_kms_vault.ssl_vault.management_endpoint
  key_shape {
    algorithm = "AES" # AES is recommended for symmetric encryption
    length    = 32    # 256-bit key
  }
  depends_on = [oci_kms_vault.ssl_vault]
}

# Output values for use in your script
output "vault_ocid" {
  value = oci_kms_vault.ssl_vault.id
}

output "key_ocid" {
  value = oci_kms_key.kms_ssl_key.id
}
