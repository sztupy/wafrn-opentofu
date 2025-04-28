# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

# Create lifecycle policy to delete temp files
resource "oci_objectstorage_object_lifecycle_policy" "wafrn_deploy_assets_lifecycle_policy" {
  count     = local.has_oci_bucket
  namespace = data.oci_objectstorage_namespace.user_namespace.namespace
  bucket    = oci_objectstorage_bucket.wafrn_backup[count.index].name

  rules {
    action      = "DELETE"
    is_enabled  = "true"
    name        = "wafrn-delete-old-backup-rule"
    time_amount = var.object_storage_wafrn_backup_days
    time_unit   = "DAYS"
  }
  depends_on = [oci_identity_policy.wafrn_basic_policies, oci_objectstorage_bucket.wafrn_backup]
}

# Create policies for wafrn based on the features
resource "oci_identity_policy" "wafrn_basic_policies" {
  count          = local.has_oci_bucket
  name           = "wafrn-basic-policies-${random_string.deploy_id.result}"
  description    = "Policies created by terraform for WAFRN Basic"
  compartment_id = var.compartment_ocid
  statements     = local.wafrn_basic_policies_statement
  freeform_tags  = local.common_tags

  provider = oci.home_region
}

locals {
  wafrn_basic_policies_statement = concat(
    local.allow_object_storage_lifecycle_statement,
    local.allow_backup_group_find_bucket,
    local.allow_backup_group_access_storage,
    local.allow_log_tenancy
  )
}

locals {
  allow_object_storage_lifecycle_statement = ["ALLOW service objectstorage-${var.region} TO manage object-family IN compartment id ${var.compartment_ocid}"]
  allow_backup_group_find_bucket           = ["ALLOW group wafrn-group-${random_string.deploy_id.result} TO read buckets IN compartment id ${var.compartment_ocid} WHERE all {target.bucket.name = 'wafrn-backup-${random_string.deploy_id.result}'} "]
  allow_backup_group_access_storage        = ["ALLOW group wafrn-group-${random_string.deploy_id.result} TO manage objects IN compartment id ${var.compartment_ocid} WHERE all {target.bucket.name = 'wafrn-backup-${random_string.deploy_id.result}'} "]
  allow_log_tenancy                        = ["ALLOW dynamic-group ${oci_identity_dynamic_group.wafrn_instance_group.name} TO use log-content IN tenancy"]
}
