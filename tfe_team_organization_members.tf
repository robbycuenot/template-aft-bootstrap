resource "tfe_team_organization_member" "aft-admin" {
  team_id = tfe_team.aft-admin.id
  organization_membership_id = tfe_organization_membership.aft.id
}

resource "tfe_team_organization_member" "aft-admin-workloads" {
  team_id = tfe_team.aft-admin-workloads.id
  organization_membership_id = tfe_organization_membership.aft-workloads.id
}