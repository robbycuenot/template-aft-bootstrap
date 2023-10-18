resource "aws_ssoadmin_account_assignment" "controller" {
  for_each = { for assignment in local.flattened_assignments : "${assignment.principal_type}___${assignment.principal}___${assignment.account_name}___${assignment.permission_set}" => assignment }

  instance_arn       = tolist(data.aws_ssoadmin_instances.instances.arns)[0]
  permission_set_arn = each.value.permission_set
  principal_id       = each.value.principal
  principal_type     = each.value.principal_type
  target_id          = local.account_map[each.value.account_name]
  target_type        = "AWS_ACCOUNT"
}
