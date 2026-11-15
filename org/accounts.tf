locals {
  accounts = {
    hub      = aws_organizations_organizational_unit.infrastructure.id
    staging  = aws_organizations_organizational_unit.workloads.id
    prod     = aws_organizations_organizational_unit.workloads.id
    tfstate  = aws_organizations_organizational_unit.infrastructure.id
    security = aws_organizations_organizational_unit.security.id
  }

  email_user   = split("@", var.email)[0]
  email_domain = split("@", var.email)[1]
}

resource "random_id" "account_email" {
  for_each = local.accounts

  byte_length = 3
}

resource "aws_organizations_account" "this" {
  for_each = local.accounts

  name      = each.key
  email     = "${local.email_user}+${each.key}-${random_id.account_email[each.key].hex}@${local.email_domain}"
  parent_id = each.value

  close_on_deletion = true
}
