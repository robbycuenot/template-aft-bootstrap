resource "tfe_variable_set" "aft" {
  name         = "aft"
  description  = "Account Factory for Terraform project variables"
  organization = tfe_organization.aft.name
  global       = false
}
