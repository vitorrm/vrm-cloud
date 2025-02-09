locals {
  privkey   = base64decode(data.oci_secrets_secretbundle.secretbundle_domain_privkey.secret_bundle_content.0.content)
  ca        = base64decode(data.oci_secrets_secretbundle.secretbundle_domain_ca.secret_bundle_content.0.content)
  fullchain = base64decode(data.oci_secrets_secretbundle.secretbundle_domain_fullchain.secret_bundle_content.0.content)
}

resource "oci_load_balancer_load_balancer" "load_balancer" {
  compartment_id = var.compartment_id
  display_name   = "vrm_load_balancer"
  shape          = "flexible"
  shape_details {
    maximum_bandwidth_in_mbps = 10
    minimum_bandwidth_in_mbps = 10
  }
  subnet_ids = [
    oci_core_subnet.public_subnet.id,
  ]
  is_private = false
}

resource "oci_load_balancer_backend_set" "load_balancer_backend_set" {
  name             = "backendSet"
  load_balancer_id = oci_load_balancer_load_balancer.load_balancer.id
  policy           = "ROUND_ROBIN"

  health_checker {
    port                = "80"
    protocol            = "HTTP"
    response_body_regex = ".*"
    url_path            = "/"
  }

  session_persistence_configuration {
    cookie_name      = "lb-session-vrm"
    disable_fallback = true
  }
}

resource "oci_load_balancer_backend" "load_balancer_backend_vrm_server" {
  #Required
  load_balancer_id = oci_load_balancer_load_balancer.load_balancer.id
  backendset_name  = oci_load_balancer_backend_set.load_balancer_backend_set.name
  ip_address       = oci_core_instance.vrm_cloud_server.private_ip
  port             = "80"
}

resource "oci_load_balancer_hostname" "load_balancer_hostname" {
  #Required
  hostname         = var.domain
  load_balancer_id = oci_load_balancer_load_balancer.load_balancer.id
  name             = "load_balancer_hostname"
}

resource "oci_load_balancer_listener" "lb_http_listener" {
  name                     = "http-listener"
  load_balancer_id         = oci_load_balancer_load_balancer.load_balancer.id
  protocol                 = "HTTP"
  port                     = 80
  default_backend_set_name = oci_load_balancer_backend_set.load_balancer_backend_set.name
  hostname_names           = [oci_load_balancer_hostname.load_balancer_hostname.name]
  connection_configuration {
    idle_timeout_in_seconds = "240"
  }
}

# HTTPS

# Upload certificate to Load Balancer
resource "oci_load_balancer_certificate" "lb_cert" {
  load_balancer_id   = oci_load_balancer_load_balancer.load_balancer.id
  certificate_name   = "duckdns-cert"
  ca_certificate     = local.ca
  public_certificate = local.fullchain
  private_key        = local.privkey
}

resource "oci_load_balancer_listener" "lb_https_listener" {
  name                     = "https-listener"
  load_balancer_id         = oci_load_balancer_load_balancer.load_balancer.id
  protocol                 = "HTTP"
  port                     = 443
  default_backend_set_name = oci_load_balancer_backend_set.load_balancer_backend_set.name
  hostname_names           = [oci_load_balancer_hostname.load_balancer_hostname.name]
  ssl_configuration {
    certificate_name        = oci_load_balancer_certificate.lb_cert.certificate_name
    protocols               = ["TLSv1.2", "TLSv1.3"]
    verify_peer_certificate = false
  }
}

output "lb_public_ip" {
  value = [oci_load_balancer_load_balancer.load_balancer.ip_address_details]
}
