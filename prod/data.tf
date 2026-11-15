data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ec2_transit_gateway" "hub" {
  filter {
    name   = "owner-id"
    values = [local.hub_account_id]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ssm_parameter" "account_id" {
  for_each = toset(["hub"])

  name = "arn:aws:ssm:eu-central-1:${local.management_account_id}:parameter/org/accounts/${each.key}"
}
