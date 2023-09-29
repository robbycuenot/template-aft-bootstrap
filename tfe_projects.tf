resource "tfe_project" "workloads" {
  name         = "Workloads"
  organization = tfe_organization.workloads.name

  # lifecycle {
  #   prevent_destroy = true
  # }
}