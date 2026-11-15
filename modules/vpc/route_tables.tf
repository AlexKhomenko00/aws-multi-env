resource "aws_route_table" "public" {
  count = length(local.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-public"
  }
}

resource "aws_route" "public_internet" {
  count = length(local.public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  for_each = local.public_subnets

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private" {
  for_each = toset(local.nat_gateway_azs)

  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-private-${each.key}"
  }
}

resource "aws_route" "private_nat" {
  for_each = toset(local.nat_gateway_azs)

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnets

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[local.private_route_target_az_by_az[each.value.az]].id
}

resource "aws_route_table" "isolated" {
  count = length(local.isolated_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-isolated"
  }
}

resource "aws_route_table_association" "isolated" {
  for_each = local.isolated_subnets

  subnet_id      = aws_subnet.isolated[each.key].id
  route_table_id = aws_route_table.isolated[0].id
}
