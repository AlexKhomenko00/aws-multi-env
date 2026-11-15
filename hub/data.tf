data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "account_id" {
  for_each = toset(["staging", "prod"])

  name = "arn:aws:ssm:eu-central-1:${local.management_account_id}:parameter/org/accounts/${each.key}"
}
