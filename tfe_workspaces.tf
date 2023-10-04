resource "tfe_workspace" "aft-framework" {
  name         = "aft-framework"
  organization = tfe_organization.aft.name
  allow_destroy_plan            = false
  assessments_enabled           = false
  auto_apply                    = false
  execution_mode                = "remote"
  file_triggers_enabled         = false
  queue_all_runs                = false
  vcs_repo {
    identifier = github_repository.aft-framework.full_name
    github_app_installation_id = data.tfe_workspace.current_workspace.vcs_repo[0].github_app_installation_id
    branch = "main"
  }

  lifecycle {
    prevent_destroy = true
  }
}
