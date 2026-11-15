data "aws_organizations_organization" "this" {}

data "aws_ssoadmin_instances" "this" {}

locals {
  sso_instance_arn = data.aws_ssoadmin_instances.this.arns[0]
  sso_instance_id  = trimprefix(local.sso_instance_arn, "arn:aws:sso:::instance/")
}
