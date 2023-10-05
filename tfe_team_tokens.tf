resource "tfe_team_token" "aft-admin" {
  # Team Token for executing aft-framework
  team_id      = tfe_team.aft-admin.id
}
