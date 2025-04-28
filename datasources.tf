# Gets a list of Availability Domains
data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}

# Gets ObjectStorage namespace
data "oci_objectstorage_namespace" "user_namespace" {
  compartment_id = var.compartment_ocid
}

# Randoms
resource "random_string" "deploy_id" {
  length  = 6
  special = false
  upper   = false
}

resource "random_string" "wafrn_admin_password" {
  length           = 24
  special          = true
  min_upper        = 3
  min_lower        = 3
  min_numeric      = 3
  min_special      = 1
  override_special = "_-"
}

# Check for resource limits
## Check available compute shape
data "oci_limits_services" "compute_services" {
  compartment_id = var.tenancy_ocid

  filter {
    name   = "name"
    values = ["compute"]
  }
}
data "oci_limits_limit_definitions" "compute_limit_definitions" {
  compartment_id = var.tenancy_ocid
  service_name   = data.oci_limits_services.compute_services.services.0.name

  filter {
    name   = "description"
    values = [local.compute_shape_description]
  }
}
data "oci_limits_resource_availability" "compute_resource_availability" {
  compartment_id      = var.tenancy_ocid
  limit_name          = data.oci_limits_limit_definitions.compute_limit_definitions.limit_definitions[0].name
  service_name        = data.oci_limits_services.compute_services.services.0.name
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[count.index].name

  count = length(data.oci_identity_availability_domains.ADs.availability_domains)
}
resource "random_shuffle" "compute_ad" {
  input        = local.compute_available_limit_ad_list
  result_count = length(local.compute_available_limit_ad_list)
}

locals {
  compute_multiplier_nodes_ocpus  = 4
  compute_available_limit_ad_list = [for limit in data.oci_limits_resource_availability.compute_resource_availability : limit.availability_domain if(limit.available - local.compute_multiplier_nodes_ocpus) >= 0]
  compute_available_limit_check = length(local.compute_available_limit_ad_list) == 0 ? (
  file("ERROR: No limits available for the chosen compute shape and number of nodes or OCPUs")) : 0
}

# Gets a list of supported images based on the shape, operating_system and operating_system_version provided
data "oci_core_images" "compute_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.image_operating_system
  operating_system_version = var.image_operating_system_version
  shape                    = local.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_identity_tenancy" "tenant_details" {
  tenancy_id = var.tenancy_ocid

  provider = oci.current_region
}

data "oci_identity_regions" "home_region" {
  filter {
    name   = "key"
    values = [data.oci_identity_tenancy.tenant_details.home_region_key]
  }

  provider = oci.current_region
}

# Available Services
data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

# Cloud Init
data "cloudinit_config" "nodes" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content      = local.cloud_init
  }
}

## Files and Templatefiles
locals {
  setup_template  = file("${path.module}/scripts/setup.sh")
  sudoers_content = file("${path.module}/scripts/sudoers_wafrn_setup")
  fluentd_content = templatefile("${path.module}/scripts/fluentd.conf.template",
    {
      log_id = oci_logging_log.wafrn_app_log.id
  })
  onsite_content = var.enable_on_site_backup ? templatefile("${path.module}/scripts/s3cfg.template",
    {
      access_key = oci_identity_customer_secret_key.wafrn_user_key[0].id
      secret_key = oci_identity_customer_secret_key.wafrn_user_key[0].key
      region     = local.region_to_deploy
      url        = "${oci_objectstorage_bucket.wafrn_backup[0].namespace}.compat.objectstorage.${local.region_to_deploy}.oraclecloud.com"
  }) : ""
  offsite_content = var.enable_off_site_backup ? templatefile("${path.module}/scripts/s3cfg.template",
    {
      access_key = var.off_site_backup_key
      secret_key = var.off_site_backup_secret
      region     = var.off_site_backup_region
      url        = var.off_site_backup_url
  }) : ""
  post_backup_content = templatefile("${path.module}/scripts/post_backup.template.sh",
    {
      has_onsite_backup   = var.enable_on_site_backup
      onsite_max_size     = var.object_storage_wafrn_backup_max_size
      onsite_bucket_name  = oci_objectstorage_bucket.wafrn_backup[0].name
      has_offsite_backup  = var.enable_off_site_backup
      offsite_max_size    = var.off_site_backup_max_size
      offsite_bucket_name = var.off_site_backup_bucket
  })
  environment_content = templatefile("${path.module}/scripts/environment.template",
    {
      domain_name           = var.wafrn_domain_name
      admin_email           = var.wafrn_admin_email
      admin_user            = var.wafrn_admin_username
      admin_password        = random_string.wafrn_admin_password.result
      bluesky_support       = var.enable_bluesky ? "Y" : ""
      pds_domain_name       = var.bluesky_domain_name
      pds_admin_username    = var.bluesky_admin_username
      email_support         = var.enable_emails ? "Y" : ""
      smtp_host             = local.email_smtp_host
      smtp_port             = local.email_smtp_port
      smtp_user             = local.email_smtp_username
      smtp_password         = local.email_smtp_password
      smtp_from             = local.sender_email_address
      send_activation_email = var.email_send_activation_emails ? "Y" : ""
  })
  cloud_init = templatefile("${path.module}/scripts/cloud-config.template.yaml",
    {
      setup_template_sh_content = base64gzip(local.setup_template)
      sudoers_content           = base64gzip(local.sudoers_content)
      environment_content       = base64gzip(local.environment_content)
      post_backup_content       = base64gzip(local.post_backup_content)
      fluentd_content           = base64gzip(local.fluentd_content)
      onsite_content            = base64gzip(local.onsite_content)
      offsite_content           = base64gzip(local.offsite_content)
  })
}

# Tags
locals {
  common_tags = {
    Reference = "Created by OCI QuickStart for WAFRN Setup"
  }
}
