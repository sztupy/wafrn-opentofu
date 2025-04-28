resource "oci_email_email_domain" "domain" {
  count          = local.has_oci_email
  compartment_id = var.compartment_ocid
  name           = local.email_domain_name
  provider       = oci.home_region
  description    = "wafrn-email-domain-${random_string.deploy_id.result}"
}

resource "oci_email_dkim" "dkim" {
  count           = local.has_oci_email
  email_domain_id = oci_email_email_domain.domain[count.index].id
  description     = "wafrn-email-dkim-${random_string.deploy_id.result}"
  provider        = oci.home_region
}

resource "oci_email_sender" "sender" {
  count          = local.has_oci_email
  compartment_id = var.compartment_ocid
  email_address  = local.sender_email_address
  provider       = oci.home_region
}

resource "oci_identity_smtp_credential" "smtp_credential" {
  count       = local.has_oci_email
  provider    = oci.home_region
  description = "wafrn-smtp-${random_string.deploy_id.result}"
  user_id     = local.user_ocid
}

data "oci_email_configuration" "email_configuration" {
  compartment_id = var.compartment_ocid
}
