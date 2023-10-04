resource "tfe_organization" "aft" {
  name  = local.tfc_aft_organization_name
  email = data.tfe_organization.current_organization.email
  collaborator_auth_policy = "two_factor_mandatory"

  lifecycle {
    prevent_destroy = true
  }
}

resource "tfe_organization" "workloads" {
  name  = local.tfc_workloads_organization_name
  email = data.tfe_organization.current_organization.email
  collaborator_auth_policy = "two_factor_mandatory"

  lifecycle {
    prevent_destroy = true
  }
}
