locals {
  accounts = data.aws_organizations_organization.current_organization.accounts
  account_map = { for account in local.accounts : account.name => account.id }
}

locals {
  flattened_assignments = flatten([
    for principal_type, principals in local.account_assignments : [
      for principal, accounts in principals : [
        for account_name, permission_sets in accounts : [
          for permission_set in permission_sets : {
            "principal"      = principal,
            "principal_type" = principal_type,
            "account_name"   = account_name,
            "permission_set" = permission_set
          }
        ]
      ]
    ]
  ])
}

locals {
  flattened_group_memberships = flatten([
    for group, users in local.group_memberships : [
      for user in users : {
        "group" = group,
        "user"  = user
      }
    ]
  ])
}