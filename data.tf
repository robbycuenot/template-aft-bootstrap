data "tfe_organization" "current_organization" {
  name = local.tfc_current_organization_name
}

data "tfe_workspace" "current_workspace" {
  name         = local.tfc_current_workspace_name
  organization = data.tfe_organization.current_organization.name
}
