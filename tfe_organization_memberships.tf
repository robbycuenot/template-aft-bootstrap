resource "tfe_organization_membership" "aft" {
  organization = data.tfe_organization.current_organization.name
  email = var.aft_email
}
