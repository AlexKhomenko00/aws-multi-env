module "label_tgw_attachment" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.label.context
  name    = "tgw-attachment"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = module.label_tgw_attachment.id
  }
}

data "aws_ec2_transit_gateway_attachments" "spoke" {
  for_each = local.workload_account_ids

  filter {
    name   = "resource-owner-id"
    values = [each.value]
  }
  filter {
    name   = "resource-type"
    values = ["vpc"]
  }
  filter {
    name   = "state"
    values = local.live_attachment_states
  }
}

data "aws_ec2_transit_gateway_attachment" "spoke" {
  for_each = local.spoke_attachment_ids

  transit_gateway_attachment_id = each.value
}

module "label_accepts" {
  for_each = local.spoke_attachment_ids
  source   = "cloudposse/label/null"
  version  = "0.25.0"

  context    = module.label.context
  name       = "accepts"
  attributes = [each.key]
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "spoke" {
  for_each = local.spoke_attachment_ids

  transit_gateway_attachment_id = each.value

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = module.label_accepts[each.key].id
  }

  lifecycle {
    precondition {
      condition     = length(data.aws_ec2_transit_gateway_attachments.spoke[each.key].ids) == 1
      error_message = "${each.key} has more than one VPC attachment; hub can't tell which to accept."
    }
    precondition {
      condition     = data.aws_ec2_transit_gateway_attachment.spoke[each.key].transit_gateway_id == aws_ec2_transit_gateway.this.id
      error_message = "${each.key}'s attachment belongs to another transit gateway."
    }
  }
}
