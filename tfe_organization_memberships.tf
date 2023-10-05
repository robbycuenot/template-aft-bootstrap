resource "tfe_organization_membership" "aft" {
  organization  = local.tfc_workloads_organization_name
  email = var.aft_user_email
}