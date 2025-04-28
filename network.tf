resource "oci_core_virtual_network" "wafrn_main_vcn" {
  cidr_block     = lookup(var.network_cidrs, "MAIN-VCN-CIDR")
  compartment_id = var.compartment_ocid
  display_name   = "wafrn-main-${random_string.deploy_id.result}"
  dns_label      = "wafrnmain${random_string.deploy_id.result}"
  freeform_tags  = local.common_tags
}

resource "oci_core_subnet" "wafrn_main_subnet" {
  cidr_block                 = lookup(var.network_cidrs, "MAIN-SUBNET-REGIONAL-CIDR")
  display_name               = "wafrn-main-${random_string.deploy_id.result}"
  dns_label                  = "wafrnmain${random_string.deploy_id.result}"
  security_list_ids          = [oci_core_security_list.wafrn_security_list.id]
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.wafrn_main_vcn.id
  route_table_id             = oci_core_route_table.wafrn_main_route_table.id
  dhcp_options_id            = oci_core_virtual_network.wafrn_main_vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = false
  freeform_tags              = local.common_tags
}

resource "oci_core_route_table" "wafrn_main_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.wafrn_main_vcn.id
  display_name   = "wafrn-main-${random_string.deploy_id.result}"
  freeform_tags  = local.common_tags

  route_rules {
    destination       = lookup(var.network_cidrs, "ALL-CIDR")
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.wafrn_internet_gateway.id
  }
}
resource "oci_core_internet_gateway" "wafrn_internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "wafrn-internet-gateway-${random_string.deploy_id.result}"
  vcn_id         = oci_core_virtual_network.wafrn_main_vcn.id
  freeform_tags  = local.common_tags
}

data "oci_core_private_ips" "app_instance_private_ip" {
  ip_address = var.instance_private_ip
  subnet_id  = oci_core_subnet.wafrn_main_subnet.id

  depends_on = [oci_core_instance.app_instance]
}

resource "oci_core_public_ip" "wafrn_ip" {
  compartment_id = var.compartment_ocid
  lifetime       = "RESERVED"
  display_name   = "wafrn-app-public-ip-${random_string.deploy_id.result}"
  private_ip_id  = data.oci_core_private_ips.app_instance_private_ip.private_ips[0]["id"]
}
