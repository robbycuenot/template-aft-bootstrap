resource "tfe_workspace" "aft-framework" {
  name         = "aft-framework"
  organization = data.tfe_organization.current_organization.name
  allow_destroy_plan            = false
  assessments_enabled           = false
  auto_apply                    = false
  execution_mode                = "remote"
  file_triggers_enabled         = false
  queue_all_runs                = false
  vcs_repo {
    identifier = "${local.github_owner}/aft-framework"
    github_app_installation_id = data.tfe_workspace.current_workspace.vcs_repo[0].github_app_installation_id
    branch = "main"
  }

  lifecycle {
    prevent_destroy = true
  }
}