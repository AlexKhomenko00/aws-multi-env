data "aws_organizations_organization" "this" {
  provider = aws.management
}

data "aws_region" "current" {
  provider = aws.management
}

data "aws_ssm_parameter" "security_account_id" {
  provider = aws.management

  name = "/org/accounts/security"
}
