resource "tfe_variable_set" "github" {
  name         = "github"
  description  = "github"
  organization = data.tfe_organization.current_organization.name
  global       = false
}