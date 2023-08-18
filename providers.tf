terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "5.32.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.48.0"
    }
  }
}

provider "github" {
  owner = local.github_owner
  token = var.github_token
}

provider "tfe" {
  token        = var.tfe_token
  organization = local.tfc_current_organization_name
}