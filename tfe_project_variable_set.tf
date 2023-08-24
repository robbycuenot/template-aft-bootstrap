resource "tfe_project_variable_set" "aft" {
  variable_set_id = tfe_variable_set.aft.id
  project_id      = data.tfe_organization.current_organization.default_project_id
}
