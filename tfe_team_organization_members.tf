resource "tfe_team_organization_member" "aft" {
  team_id = tfe_team.aft-workloads.id
  organization_membership_id = tfe_organization_membership.aft.id
}