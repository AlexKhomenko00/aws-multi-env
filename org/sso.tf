import {
  to = aws_ssoadmin_permission_set.admin
  id = "arn:aws:sso:::permissionSet/${local.sso_instance_id}/ps-6987a074faa19acc,${local.sso_instance_arn}"
}

resource "aws_ssoadmin_permission_set" "admin" {
  name             = "AdministratorAccess"
  instance_arn     = data.aws_ssoadmin_instances.this.arns[0]
  session_duration = "PT2H"
}

import {
  to = aws_ssoadmin_managed_policy_attachment.admin
  id = "arn:aws:iam::aws:policy/AdministratorAccess,arn:aws:sso:::permissionSet/${local.sso_instance_id}/ps-6987a074faa19acc,${local.sso_instance_arn}"
}

resource "aws_ssoadmin_managed_policy_attachment" "admin" {
  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
}

import {
  to = aws_identitystore_group.admins
  id = "${data.aws_ssoadmin_instances.this.identity_store_ids[0]}/f3349882-d0e1-7087-731a-644ebb1cb1b2"
}

resource "aws_identitystore_group" "admins" {
  identity_store_id = data.aws_ssoadmin_instances.this.identity_store_ids[0]
  display_name      = "admins"
}
