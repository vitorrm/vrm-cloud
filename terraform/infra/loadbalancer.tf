resource "oci_load_balancer_load_balancer" "load_balancer" {
  compartment_id = var.compartment_id
  display_name   = "alwaysFreeLoadBalancer"
  shape          = "flexible"
  shape_details {
    maximum_bandwidth_in_mbps = 10
    minimum_bandwidth_in_mbps = 10
  }
  subnet_ids = [
    oci_core_subnet.public_subnet.id,
  ]
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
    cookie_name      = "lb-session1"
    disable_fallback = true
  }
}

resource "oci_load_balancer_backend" "load_balancer_backed_vrm_server" {
  #Required
  load_balancer_id = oci_load_balancer_load_balancer.load_balancer.id
  backendset_name  = oci_load_balancer_backend_set.load_balancer_backend_set.name
  ip_address       = oci_core_instance.vrm_cloud_server.private_ip
  port             = "80"
}

resource "oci_load_balancer_hostname" "load_balancer_hostname" {
  #Required
  hostname         = "vrmcloud.duckdns.org"
  load_balancer_id = oci_load_balancer_load_balancer.load_balancer.id
  name             = "load_balancer_hostname"
}

resource "oci_load_balancer_listener" "lb_http_listener" {
  load_balancer_id         = oci_load_balancer_load_balancer.load_balancer.id
  protocol                 = "HTTP"
  name                     = "http"
  port                     = 80
  default_backend_set_name = oci_load_balancer_backend_set.load_balancer_backend_set.name
  hostname_names           = [oci_load_balancer_hostname.load_balancer_hostname.name]
  rule_set_names           = [oci_load_balancer_rule_set.lb_rule_set.name]
  connection_configuration {
    idle_timeout_in_seconds = "240"
  }
}

resource "oci_load_balancer_rule_set" "lb_rule_set" {
  items {
    action = "ADD_HTTP_REQUEST_HEADER"
    header = "lb_self_signed_cert_header_name"
    value  = "lb_self_signed_cert_header_value"
  }

  items {
    action          = "CONTROL_ACCESS_USING_HTTP_METHODS"
    allowed_methods = ["GET", "POST"]
    status_code     = "405"
  }

  load_balancer_id = oci_load_balancer_load_balancer.load_balancer.id
  name             = "lb_rule_set_name"
}

resource "tls_private_key" "lb_private_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "lb_self_signed_cert" {
  key_algorithm   = "ECDSA"
  private_key_pem = tls_private_key.lb_private_key.private_key_pem

  subject {
    organization = "Oracle"
    country      = "US"
    locality     = "Austin"
    province     = "TX"
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
    "cert_signing"
  ]

  is_ca_certificate = true
}

resource "oci_load_balancer_certificate" "lb_certificate" {
  load_balancer_id   = oci_load_balancer_load_balancer.load_balancer.id
  ca_certificate     = tls_self_signed_cert.lb_self_signed_cert.cert_pem
  certificate_name   = "lb_certificate"
  private_key        = tls_private_key.lb_private_key.private_key_pem
  public_certificate = tls_self_signed_cert.lb_self_signed_cert.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

resource "oci_load_balancer_listener" "lb_https_listener" {
  load_balancer_id         = oci_load_balancer_load_balancer.load_balancer.id
  protocol                 = "HTTP"
  name                     = "https"
  port                     = 443
  default_backend_set_name = oci_load_balancer_backend_set.load_balancer_backend_set.name
  ssl_configuration {
    certificate_name        = oci_load_balancer_certificate.lb_certificate.certificate_name
    verify_peer_certificate = false
  }
}

output "lb_public_ip" {
  value = [oci_load_balancer_load_balancer.load_balancer.ip_address_details]
}
