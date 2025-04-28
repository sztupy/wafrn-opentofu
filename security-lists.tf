resource "oci_core_security_list" "wafrn_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.wafrn_main_vcn.id
  display_name   = "wafrn-main-${random_string.deploy_id.result}"
  freeform_tags  = local.common_tags
  ingress_security_rules {
    protocol = local.tcp_protocol_number
    source   = lookup(var.network_cidrs, "ALL-CIDR")

    tcp_options {
      max = local.http_port_number
      min = local.http_port_number
    }
  }

  ingress_security_rules {
    protocol = local.tcp_protocol_number
    source   = lookup(var.network_cidrs, "ALL-CIDR")

    tcp_options {
      max = local.https_port_number
      min = local.https_port_number
    }
  }

  ingress_security_rules {
    protocol = local.udp_protocol_number
    source   = lookup(var.network_cidrs, "ALL-CIDR")

    udp_options {
      max = local.https_port_number
      min = local.https_port_number
    }
  }

  ingress_security_rules {
    protocol = local.tcp_protocol_number
    source   = lookup(var.network_cidrs, "ALL-CIDR")

    tcp_options {
      max = local.ssh_port_number
      min = local.ssh_port_number
    }
  }

  ingress_security_rules {
    protocol = local.icmp_protocol_number
    source   = lookup(var.network_cidrs, "ALL-CIDR")
  }

  egress_security_rules {
    protocol    = local.all_protocols
    destination = lookup(var.network_cidrs, "ALL-CIDR")
  }
}

locals {
  http_port_number     = "80"
  https_port_number    = "443"
  ssh_port_number      = "22"
  icmp_protocol_number = "1"
  tcp_protocol_number  = "6"
  udp_protocol_number  = "17"
  all_protocols        = "all"
}
