resource "aws_eip" "nat" {
  for_each = toset(local.nat_gateway_azs)

  domain = "vpc"

  tags = {
    Name = "${var.name}-nat-${each.key}"
  }
}

resource "aws_nat_gateway" "this" {
  for_each = toset(local.nat_gateway_azs)

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[local.public_subnet_cidr_by_az[each.key]].id

  depends_on = [aws_internet_gateway.this]

  tags = {
    Name = "${var.name}-nat-${each.key}"
  }

  lifecycle {
    precondition {
      condition     = contains(keys(local.public_subnet_cidr_by_az), each.key)
      error_message = "No public subnet exists in AZ ${each.key}, needed to place its NAT gateway. Add a public_subnet_cidrs entry that lands in that AZ, or set single_nat_gateway = true."
    }
  }
}
