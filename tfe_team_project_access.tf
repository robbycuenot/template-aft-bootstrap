resource "tfe_team_project_access" "aft-admin" {
  access       = "admin"
  team_id      = tfe_team.aft-admin.id
  project_id   = tfe_organization.aft.default_project_id
}

resource "tfe_team_project_access" "aft-workloads" {
  access       = "admin"
  team_id      = tfe_team.aft-workloads.id
  project_id   = tfe_organization.workloads.default_project_id
}
