# OCI common
variable "tenancy_ocid" {}
variable "region" {}
variable "compartment_ocid" {}
variable "user_ocid" {
  default = ""
}
variable "current_user_ocid" {
  default = ""
}
variable "fingerprint" {
  default = ""
}

# Instance setup
variable "private_key_path" {
  default = ""
}

variable "public_ssh_key" {
  default = ""
}

variable "network_cidrs" {
  type = map(string)

  default = {
    MAIN-VCN-CIDR             = "10.1.0.0/16"
    MAIN-SUBNET-REGIONAL-CIDR = "10.1.21.0/24"
    ALL-CIDR                  = "0.0.0.0/0"
  }
}

variable "instance_private_ip" {
  default = "10.1.21.21"
}

# Compute
variable "generate_public_ssh_key" {
  default = true
}
variable "instance_ocpus" {
  default = 4
}
variable "instance_shape_config_memory_in_gbs" {
  default = 24
}
variable "image_operating_system" {
  default = "Canonical Ubuntu"
}
variable "image_operating_system_version" {
  default = "24.04"
}
variable "instance_volume_size" {
  default = 200
}

variable "oracle_client_version" {
  default = "19.10"
}

# WAFRN config
variable "wafrn_domain_name" {
}
variable "wafrn_admin_email" {
}
variable "wafrn_admin_username" {
}
variable "enable_bluesky" {
  default = true
}
variable "bluesky_domain_name" {
  default = ""
}
variable "bluesky_admin_username" {
  default = ""
}

# Email sending
variable "enable_emails" {
  default = true
}
variable "sender_email_address" {
  default = ""
}
variable "use_third_party_smtp" {
  default = false
}
variable "email_smtp_host" {
  default = ""
}
variable "email_smtp_port" {
  default = 587
}
variable "email_smtp_username" {
  default = ""
}
variable "email_smtp_password" {
  default = ""
}

# On-site backup
variable "enable_on_site_backup" {
  default = true
}
variable "object_storage_wafrn_backup_max_size" {
  default = 10
}
variable "object_storage_wafrn_backup_days" {
  default = 30
}

# Off-site backup
variable "enable_off_site_backup" {
  default = false
}
variable "email_send_activation_emails" {
  default = true
}
variable "off_site_backup_key" {
  default = ""
}
variable "off_site_backup_secret" {
  default = ""
}
variable "off_site_backup_url" {
  default = ""
}
variable "off_site_backup_region" {
  default = ""
}
variable "off_site_backup_bucket" {
  default = ""
}
variable "off_site_backup_max_size" {
  default = 10
}

# ORM Schema visual control variables
variable "show_advanced" {
  default = false
}

variable "installer_location" {
  default = "https://raw.githubusercontent.com/gabboman/wafrn/main/install/installer.sh"
}

# Always Free only or support other shapes
variable "use_only_always_free_eligible_resources" {
  default = true
}

## Calculated values - Always Free Locals
locals {
  instance_volume_size                 = var.use_only_always_free_eligible_resources ? max(200, var.instance_volume_size) : var.instance_volume_size
  object_storage_wafrn_backup_max_size = var.use_only_always_free_eligible_resources ? max(10, var.object_storage_wafrn_backup_max_size) : var.object_storage_wafrn_backup_max_size
  compute_shape_description            = "Cores for Standard.A1 based VM and BM Instances"
  instance_shape                       = "VM.Standard.A1.Flex"

  has_oci_email       = var.enable_emails ? (var.use_third_party_smtp ? 0 : 1) : 0
  email_smtp_host     = var.enable_emails ? (var.use_third_party_smtp ? var.email_smtp_host : data.oci_email_configuration.email_configuration.smtp_submit_endpoint) : ""
  email_smtp_port     = var.enable_emails ? (var.use_third_party_smtp ? var.email_smtp_port : 587) : 587
  email_smtp_username = var.enable_emails ? (var.use_third_party_smtp ? var.email_smtp_username : oci_identity_smtp_credential.smtp_credential[0].username) : ""
  email_smtp_password = var.enable_emails ? (var.use_third_party_smtp ? var.email_smtp_password : oci_identity_smtp_credential.smtp_credential[0].password) : ""

  sender_email_address = (var.sender_email_address != "") ? var.sender_email_address : format("noreply@%s", var.wafrn_domain_name)
  email_domain_name    = split("@", local.sender_email_address)[1]

  has_oci_bucket = var.enable_on_site_backup ? 1 : 0

  dns_spf_value  = var.enable_emails ? (var.use_third_party_smtp ? "" : "v=spf1 include:rp.oracleemaildelivery.com include:ap.rp.oracleemaildelivery.com include:eu.rp.oracleemaildelivery.com ~all") : ""
  dns_dkim_key   = var.enable_emails ? (var.use_third_party_smtp ? "" : oci_email_dkim.dkim[0].dns_subdomain_name) : ""
  dns_dkim_value = var.enable_emails ? (var.use_third_party_smtp ? "" : oci_email_dkim.dkim[0].cname_record_value) : ""
}
