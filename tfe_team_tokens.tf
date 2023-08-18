resource "tfe_team_token" "aft-admin" {
  # Team Token for executing aft-framework
  team_id      = tfe_team.aft-admin.id

  # Expiry can be enabled for extra security, but
  # will require this token to be regenerated before any
  # downstream AFT actions can be executed.

  # force_regenerate = true
  # expired_at = timeadd(timestamp(), "1h")
}
