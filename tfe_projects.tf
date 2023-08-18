resource "tfe_project" "workloads" {
  name         = "Workloads"
  organization = data.tfe_organization.current_organization.name

  lifecycle {
    prevent_destroy = true
  }
}