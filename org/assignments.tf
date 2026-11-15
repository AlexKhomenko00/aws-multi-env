resource "aws_ssoadmin_account_assignment" "admin" {
  for_each = local.account_ids

  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  principal_id       = aws_identitystore_group.admins.group_id
  principal_type     = "GROUP"
  target_id          = each.value
  target_type        = "AWS_ACCOUNT"
}

import {
  to = aws_ssoadmin_account_assignment.management
  id = "f3349882-d0e1-7087-731a-644ebb1cb1b2,GROUP,024665166160,AWS_ACCOUNT,arn:aws:sso:::permissionSet/${local.sso_instance_id}/ps-6987a074faa19acc,${local.sso_instance_arn}"
}

resource "aws_ssoadmin_account_assignment" "management" {
  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  principal_id       = aws_identitystore_group.admins.group_id
  principal_type     = "GROUP"
  target_id          = data.aws_organizations_organization.this.master_account_id
  target_type        = "AWS_ACCOUNT"
}
