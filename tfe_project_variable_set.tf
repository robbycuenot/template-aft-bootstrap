resource "tfe_project_variable_set" "github" {
  variable_set_id = tfe_variable_set.github.id
  project_id      = data.tfe_organization.current_organization.default_project_id
}