variable "aft_email" {
  description = "AFT user email address"
  sensitive    = false
}

variable "github_token" {
  description = "GitHub personal access token"
  sensitive    = true
}

variable "TFC_WORKSPACE_SLUG" {
  description = "DO NOT SET - Managed by TFC - Terraform Cloud workspace slug"
  sensitive    = true
}

variable "tfe_token" {
  description = "Terraform Cloud API token"
  sensitive    = true
}
