locals {
  account_ids = { for name, account in aws_organizations_account.this : name => account.id }
}

resource "aws_ssm_parameter" "account_id" {
  for_each = local.account_ids

  name  = "/org/accounts/${each.key}"
  type  = "String"
  tier  = "Advanced"
  value = each.value
}

module "label_account_ids_for_hub" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.label.context
  name    = "account-ids-for-hub"
}

resource "aws_ram_resource_share" "account_ids_for_hub" {
  name                      = module.label_account_ids_for_hub.id
  allow_external_principals = false
}

resource "aws_ram_resource_association" "account_ids_for_hub" {
  for_each = toset(["staging", "prod"])

  resource_arn       = aws_ssm_parameter.account_id[each.key].arn
  resource_share_arn = aws_ram_resource_share.account_ids_for_hub.arn
}

resource "aws_ram_principal_association" "account_ids_for_hub" {
  principal          = local.account_ids["hub"]
  resource_share_arn = aws_ram_resource_share.account_ids_for_hub.arn
}

module "label_account_ids_for_workloads" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.label.context
  name    = "account-ids-for-workloads"
}

resource "aws_ram_resource_share" "account_ids_for_workloads" {
  name                      = module.label_account_ids_for_workloads.id
  allow_external_principals = false
}

resource "aws_ram_resource_association" "account_ids_for_workloads" {
  resource_arn       = aws_ssm_parameter.account_id["hub"].arn
  resource_share_arn = aws_ram_resource_share.account_ids_for_workloads.arn
}

resource "aws_ram_principal_association" "account_ids_for_workloads" {
  for_each = toset(["staging", "prod"])

  principal          = local.account_ids[each.key]
  resource_share_arn = aws_ram_resource_share.account_ids_for_workloads.arn
}
