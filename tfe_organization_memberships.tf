resource "tfe_organization_membership" "aft" {
  organization = data.tfe_organization.current_organization.name
  email = var.aft_email
}

resource "tfe_organization_membership" "aft-workloads" {
  organization = tfe_organization.workloads.name
  email = var.aft_email
}
