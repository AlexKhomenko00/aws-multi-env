module "label_to_hub" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.label.context
  name    = "to-hub"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  transit_gateway_id = data.aws_ec2_transit_gateway.hub.id
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.isolated_subnet_ids

  tags = {
    Name = module.label_to_hub.id
  }
}

resource "aws_route" "isolated_to_hub" {
  route_table_id         = module.vpc.isolated_route_table_id
  destination_cidr_block = module.network_plan.vpc_cidrs["hub"]
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.hub.transit_gateway_id
}

resource "aws_route" "private_to_hub" {
  for_each = module.vpc.private_route_table_ids

  route_table_id         = each.value
  destination_cidr_block = module.network_plan.vpc_cidrs["hub"]
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.hub.transit_gateway_id
}
