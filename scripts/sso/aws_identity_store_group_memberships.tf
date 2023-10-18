resource "aws_identitystore_group_membership" "controller" {
  for_each = { for membership in local.flattened_group_memberships : "${membership.group}___${membership.user}" => membership }

  group_id = each.value.group
  member_id  = each.value.user

  identity_store_id = tolist(data.aws_ssoadmin_instances.instances.identity_store_ids)[0]
}
