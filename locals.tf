locals {
  repos = {
    aft-framework = {
      repo_name = "aft-framework"
      template_name = "template-aft-framework"
    },
    aft-account-requests = {
      repo_name = "aft-account-requests"
      template_name = "template-aft-account-requests"
    },
    aft-account-customizations = {
      repo_name = "aft-account-customizations"
      template_name = "template-aft-account-customizations"
    },
    aft-account-provisioning-customizations = {
      repo_name = "aft-account-provisioning-customizations"
      template_name = "template-aft-account-provisioning-customizations"
    },
    aft-global-customizations = {
      repo_name = "aft-global-customizations"
      template_name = "template-aft-global-customizations"
    }
  }
  templates_organization = "robbycuenot"

  tfc_workspace_slug_split = split("/", var.TFC_WORKSPACE_SLUG)
  tfc_current_organization_name    = local.tfc_workspace_slug_split[0]
  tfc_current_workspace_name       = local.tfc_workspace_slug_split[1]

  github_identifier = data.tfe_workspace.current_workspace.vcs_repo["0"].identifier
  github_identifier_split = split("/", local.github_identifier)
  github_owner = local.github_identifier_split[0]
}