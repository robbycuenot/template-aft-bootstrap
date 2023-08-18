resource "tfe_team_token" "aft-admin" {
  team_id      = tfe_team.aft-admin.id
}
