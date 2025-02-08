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
  load_balancer_id         = oci_load_balancer_load_balancer.load_balancer.id
  protocol                 = "HTTP"
  name                     = "http-listener"
  port                     = 80
  default_backend_set_name = oci_load_balancer_backend_set.load_balancer_backend_set.name
  hostname_names           = [oci_load_balancer_hostname.load_balancer_hostname.name]
  connection_configuration {
    idle_timeout_in_seconds = "240"
  }
}

output "lb_public_ip" {
  value = [oci_load_balancer_load_balancer.load_balancer.ip_address_details]
}
