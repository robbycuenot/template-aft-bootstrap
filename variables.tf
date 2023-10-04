variable "github_token" {
  description = "GitHub personal access token"
  sensitive    = true
}

variable "tfc_aft_organization_name" {
  description = "The name of the AFT organization in Terraform Cloud."
  type        = string
  default     = ""
}

variable "tfc_workloads_organization_name" {
  description = "The name of the workloads organization in Terraform Cloud."
  type        = string
  default     = ""
}

variable "TFC_WORKSPACE_SLUG" {
  description = "DO NOT SET - Managed by TFC - Terraform Cloud workspace slug"
  sensitive    = true
}

variable "tfe_token" {
  description = "Terraform Cloud API token"
  sensitive    = true
}
