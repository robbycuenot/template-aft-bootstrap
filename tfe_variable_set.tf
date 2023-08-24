resource "tfe_variable_set" "aft" {
  name         = "aft"
  description  = "Account Factory for Terraform project variables"
  organization = data.tfe_organization.current_organization.name
  global       = false
}
