locals {
  vcn_cidr_block            = "10.1.0.0/16"
  public_subnet_cidr_block  = "10.1.1.0/24"
  private_subnet_cidr_block = "10.1.10.0/24"
}

# Virtual Cloud Network (VCN) for the VRM environment
resource "oci_core_vcn" "vrm_vcn" {
  compartment_id = var.compartment_id
  cidr_block     = local.vcn_cidr_block
  display_name   = "vrm-vcn"
  dns_label      = "vrmvcn"
}

# Internet Gateway (for public subnet/NAT instance)
resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_id
  display_name   = "internet-gateway"
  vcn_id         = oci_core_vcn.vrm_vcn.id
}

resource "oci_core_public_ip" "reserved_public_ip" {
  compartment_id = var.compartment_id
  lifetime       = "RESERVED"
}

# NAT Gateway for outbound internet access from the private subnet
resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vrm_vcn.id
  public_ip_id   = oci_core_public_ip.reserved_public_ip.id
  display_name   = "nat-gateway"
}

# Public Subnet 
resource "oci_core_subnet" "public_subnet" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vrm_vcn.id
  cidr_block                 = local.public_subnet_cidr_block
  display_name               = "public-subnet"
  dns_label                  = "publicnat"
  security_list_ids          = [oci_core_security_list.public_security_list.id]
  route_table_id             = oci_core_route_table.public_route_table.id
  dhcp_options_id            = oci_core_vcn.vrm_vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = false # Allow public IPs
}

# Route Table for Public Subnet (routes to Internet Gateway)
resource "oci_core_route_table" "public_route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vrm_vcn.id
  display_name   = "public-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

# Security List for Public Subnet (allow SSH and NAT traffic)
resource "oci_core_security_list" "public_security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vrm_vcn.id
  display_name   = "public-security-list"

  # Allow HTTP inbound
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      max = 80
      min = 80
    }
  }

  # Allow HTTPS inbound
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      max = 443
      min = 443
    }
  }

  # Allow all outbound traffic
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

# Route Table for Private Subnet (route traffic through NAT instance)
resource "oci_core_route_table" "private_route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vrm_vcn.id
  display_name   = "private-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_nat_gateway.nat_gateway.id # Route via NAT instance
  }
}

# Private Subnet within the VCN for internal resources
resource "oci_core_subnet" "private_subnet" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vrm_vcn.id
  cidr_block                 = local.private_subnet_cidr_block
  display_name               = "private-subnet"
  dns_label                  = "vrmsubnet"
  security_list_ids          = [oci_core_security_list.private_security_list.id]
  route_table_id             = oci_core_route_table.private_route_table.id
  dhcp_options_id            = oci_core_vcn.vrm_vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = true
}

# Security List to define ingress and egress rules for the subnet
resource "oci_core_security_list" "private_security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vrm_vcn.id
  display_name   = "private-security-list"
  # Egress rule to allow outbound traffic to any destination
  egress_security_rules {
    description = "SSH outbound"
    protocol    = "6"
    destination = "0.0.0.0/0"
  }
  # Ingress rule to allow SSH access (port 22) from any source within private net
  ingress_security_rules {
    description = "SSH inbound"
    protocol    = "6"
    source      = local.private_subnet_cidr_block
    source_type = "CIDR_BLOCK"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  # Ingress rule to HTTP from any load balancer
  ingress_security_rules {
    description = "HTTP 80 inbound"
    protocol    = "6"
    source      = local.public_subnet_cidr_block
    source_type = "CIDR_BLOCK"
    tcp_options {
      max = "80"
      min = "80"
    }
  }

}
