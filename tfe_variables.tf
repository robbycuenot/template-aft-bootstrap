resource "tfe_variable" "AWS_ACCESS_KEY_ID" {
  key          = "AWS_ACCESS_KEY_ID"
  value        = ""
  category     = "env"
  workspace_id = tfe_workspace.aft-framework.id
  description  = "AWS Access Key ID"

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "tfe_variable" "AWS_REGION" {
  key          = "AWS_REGION"
  value        = "us-east-1"
  category     = "env"
  workspace_id = tfe_workspace.aft-framework.id
  description  = "AWS Control Tower Region"

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "tfe_variable" "AWS_SECRET_ACCESS_KEY" {
  key          = "AWS_SECRET_ACCESS_KEY"
  value        = ""
  category     = "env"
  workspace_id = tfe_workspace.aft-framework.id
  description  = "AWS Secret Access Key"
  sensitive    = true

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "tfe_variable" "AWS_SESSION_TOKEN" {
  key          = "AWS_SESSION_TOKEN"
  value        = ""
  category     = "env"
  workspace_id = tfe_workspace.aft-framework.id
  description  = "AWS Session Token"
  sensitive    = true

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "tfe_variable" "terraform_aft_token" {
  key          = "terraform_aft_token"
  value        = tfe_team_token.aft-admin.token
  category     = "terraform"
  variable_set_id = tfe_variable_set.aft.id
  description  = "Terraform Team Token"
  sensitive    = true
}

resource "tfe_variable" "terraform_workloads_token" {
  key          = "terraform_workloads_token"
  value        = tfe_team_token.aft-workloads.token
  category     = "terraform"
  variable_set_id = tfe_variable_set.aft.id
  description  = "Terraform Workloads Team Token"
  sensitive    = true
}

resource "tfe_variable" "repo_aft_account_customizations" {
  key          = "repo_aft_account_customizations"
  value        = github_repository.aft-account-customizations.full_name
  category     = "terraform"
  workspace_id = tfe_workspace.aft-framework.id
  description  = "Repository for AFT Account Customizations"

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "tfe_variable" "repo_aft_account_provisioning_customizations" {
  key          = "repo_aft_account_provisioning_customizations"
  value        = github_repository.aft-account-provisioning-customizations.full_name
  category     = "terraform"
  workspace_id = tfe_workspace.aft-framework.id
  description  = "Repository for AFT Account Provisioning Customizations"

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "tfe_variable" "repo_aft_account_requests" {
  key          = "repo_aft_account_requests"
  value        = github_repository.aft-account-requests.full_name
  category     = "terraform"
  workspace_id = tfe_workspace.aft-framework.id
  description  = "Repository for AFT Account Requests"

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "tfe_variable" "repo_aft_framework" {
  key          = "repo_aft_framework"
  value        = github_repository.aft-framework.full_name
  category     = "terraform"
  workspace_id = tfe_workspace.aft-framework.id
  description  = "Repository for AFT Framework"

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "tfe_variable" "repo_aft_global_customizations" {
  key          = "repo_aft_global_customizations"
  value        = github_repository.aft-global-customizations.full_name
  category     = "terraform"
  workspace_id = tfe_workspace.aft-framework.id
  description  = "Repository for AFT Global Customizations"

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "tfe_variable" "ct_management_account_id" {
  key          = "ct_management_account_id"
  value        = ""
  category     = "terraform"
  workspace_id = tfe_workspace.aft-framework.id
  description  = "Control Tower Management Account ID"

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "tfe_variable" "log_archive_account_id" {
  key          = "log_archive_account_id"
  value        = ""
  category     = "terraform"
  workspace_id = tfe_workspace.aft-framework.id
  description  = "Control Tower Log Archive Account ID"

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "tfe_variable" "audit_account_id" {
  key          = "audit_account_id"
  value        = ""
  category     = "terraform"
  workspace_id = tfe_workspace.aft-framework.id
  description  = "Control Tower Audit Account ID"

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "tfe_variable" "aft_management_account_id" {
  key          = "aft_management_account_id"
  value        = ""
  category     = "terraform"
  workspace_id = tfe_workspace.aft-framework.id
  description  = "Control Tower AFT Management Account ID"

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "tfe_variable" "github_token" {
  key             = "github_token"
  value           = var.github_token
  category        = "terraform"
  variable_set_id = tfe_variable_set.aft.id
  description     = "GitHub Token for creating account repos"
  sensitive       = true

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "tfe_variable" "github_installation_id" {
  key             = "github_installation_id"
  value           = data.tfe_workspace.current_workspace.vcs_repo[0].github_app_installation_id
  category        = "terraform"
  variable_set_id = tfe_variable_set.aft.id
  description     = "GitHub installation ID"
  sensitive       = true

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "tfe_variable" "github_owner" {
  key             = "github_owner"
  value           = local.github_owner
  category        = "terraform"
  variable_set_id = tfe_variable_set.aft.id
  description     = "Github Owner"
  sensitive       = false

  lifecycle {
    ignore_changes = [ value ]
  }
}
