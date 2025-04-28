resource "oci_objectstorage_bucket" "wafrn_backup" {
  count          = local.has_oci_bucket
  compartment_id = var.compartment_ocid
  name           = "wafrn-backup-${random_string.deploy_id.result}"
  namespace      = data.oci_objectstorage_namespace.user_namespace.namespace
  freeform_tags  = local.common_tags
  depends_on     = [oci_identity_policy.wafrn_basic_policies]
  access_type    = "NoPublicAccess"
}

resource "oci_identity_user" "wafrn_user" {
  count          = local.has_oci_bucket
  compartment_id = var.compartment_ocid
  description    = "wafrn-user-${random_string.deploy_id.result}"
  name           = "wafrn-user-${random_string.deploy_id.result}"
  email          = "wafrn-user-${random_string.deploy_id.result}@${var.wafrn_domain_name}"
}

resource "oci_identity_group" "wafrn_group" {
  count          = local.has_oci_bucket
  compartment_id = var.compartment_ocid
  description    = "wafrn-group-${random_string.deploy_id.result}"
  name           = "wafrn-group-${random_string.deploy_id.result}"
}

resource "oci_identity_user_group_membership" "wafrn_group_membership" {
  count    = local.has_oci_bucket
  group_id = oci_identity_group.wafrn_group[count.index].id
  user_id  = oci_identity_user.wafrn_user[count.index].id
}

resource "oci_identity_customer_secret_key" "wafrn_user_key" {
  count        = local.has_oci_bucket
  display_name = "wafrn-user-${random_string.deploy_id.result}"
  user_id      = oci_identity_user.wafrn_user[count.index].id
}
