resource "tfe_team" "aft-admin" {
  name         = "aft-admin"
  organization = data.tfe_organization.current_organization.name
  visibility   = "secret"
  organization_access {
    manage_policies = false
    manage_policy_overrides = false
    manage_workspaces = true
    manage_vcs_settings = false
    manage_providers = false
    manage_modules = false
    manage_run_tasks = false
    manage_projects = false
    manage_membership = false
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "tfe_team" "aft-admin-workloads" {
  name         = "aft-admin"
  organization = tfe_organization.workloads.name
  visibility   = "secret"
  organization_access {
    manage_policies = false
    manage_policy_overrides = false
    manage_workspaces = true
    manage_vcs_settings = false
    manage_providers = false
    manage_modules = false
    manage_run_tasks = false
    manage_projects = false
    manage_membership = false
  }

  lifecycle {
    prevent_destroy = true
  }
}
