locals {
  private_isolated_route_table_ids = concat(
    values(aws_route_table.private)[*].id,
    aws_route_table.isolated[*].id,
  )

  interface_endpoints = { for k, v in var.endpoints : k => v if v.type == "Interface" }
}

resource "aws_security_group" "endpoints" {
  for_each = local.interface_endpoints

  name   = "${var.name}-${replace(each.key, ".", "-")}-endpoint"
  vpc_id = aws_vpc.this.id
}

resource "aws_vpc_endpoint" "this" {
  for_each = var.endpoints

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
  vpc_endpoint_type = each.value.type

  route_table_ids = each.value.type == "Gateway" ? local.private_isolated_route_table_ids : null

  subnet_ids          = each.value.type == "Interface" ? values(aws_subnet.private)[*].id : null
  security_group_ids  = each.value.type == "Interface" ? [aws_security_group.endpoints[each.key].id] : null
  private_dns_enabled = each.value.type == "Interface" ? true : null

  tags = {
    Name = "${var.name}-${replace(each.key, ".", "-")}"
  }
}
