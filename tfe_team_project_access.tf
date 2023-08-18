resource "tfe_team_project_access" "aft-admin" {
  access       = "admin"
  team_id      = tfe_team.aft-admin.id
  project_id   = data.tfe_organization.current_organization.default_project_id
}

resource "tfe_team_project_access" "workloads" {
  access       = "admin"
  team_id      = tfe_team.aft-admin.id
  project_id   = tfe_project.workloads.id
}
