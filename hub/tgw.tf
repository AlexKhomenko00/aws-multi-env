module "label_tgw" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.label.context
  name    = "tgw"
}

resource "aws_ec2_transit_gateway" "this" {
  description = "hub-and-spoke TGW, RAM-shared to staging/prod"

  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name = module.label_tgw.id
  }
}

module "label_tgw_rt" {
  for_each = toset(["hub", "spokes"])
  source   = "cloudposse/label/null"
  version  = "0.25.0"

  context    = module.label_tgw.context
  attributes = ["rt", each.key]
}

resource "aws_ec2_transit_gateway_route_table" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = {
    Name = module.label_tgw_rt["hub"].id
  }
}

resource "aws_ec2_transit_gateway_route_table" "spokes" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = {
    Name = module.label_tgw_rt["spokes"].id
  }
}
