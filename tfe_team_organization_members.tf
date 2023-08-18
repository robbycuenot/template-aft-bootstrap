resource "tfe_team_organization_member" "aft-admin" {
  team_id = tfe_team.aft-admin.id
  organization_membership_id = tfe_organization_membership.aft.id
}