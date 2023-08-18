resource "tfe_variable" "AWS_ACCESS_KEY_ID" {
  key          = "AWS_ACCESS_KEY_ID"
  value        = ""
  category     = "env"
  workspace_id = tfe_workspace.aft-framework.id
  description  = "AWS Access Key ID"
}

resource "tfe_variable" "AWS_REGION" {
  key          = "AWS_REGION"
  value        = "us-east-1"
  category     = "env"
  workspace_id = tfe_workspace.aft-framework.id
  description  = "AWS Control Tower Region"
}

resource "tfe_variable" "AWS_SECRET_ACCESS_KEY" {
  key          = "AWS_SECRET_ACCESS_KEY"
  value        = ""
  category     = "env"
  workspace_id = tfe_workspace.aft-framework.id
  description  = "AWS Secret Access Key"
  sensitive    = true
}

resource "tfe_variable" "AWS_SESSION_TOKEN" {
  key          = "AWS_SESSION_TOKEN"
  value        = ""
  category     = "env"
  workspace_id = tfe_workspace.aft-framework.id
  description  = "AWS Session Token"
  sensitive    = true
}

resource "tfe_variable" "terraform_token" {
  key          = "terraform_token"
  value        = tfe_team_token.aft-admin.token
  category     = "terraform"
  workspace_id = tfe_workspace.aft-framework.id
  description  = "Terraform Team Token"
  sensitive    = true
}
