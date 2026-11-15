module "label_tgw_share" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.label.context
  name    = "tgw-share"
}

resource "aws_ram_resource_share" "tgw" {
  name                      = module.label_tgw_share.id
  allow_external_principals = false

  tags = {
    Name = module.label_tgw_share.id
  }
}

resource "aws_ram_resource_association" "tgw" {
  resource_arn       = aws_ec2_transit_gateway.this.arn
  resource_share_arn = aws_ram_resource_share.tgw.arn
}

resource "aws_ram_principal_association" "tgw" {
  for_each = local.workload_account_ids

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.tgw.arn
}
