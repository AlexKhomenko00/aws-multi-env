resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.key
  availability_zone       = each.value.az
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = {
    Name = "${var.name}-public-${each.value.az}-${each.value.seq}"
  }
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.key
  availability_zone = each.value.az

  tags = {
    Name = "${var.name}-private-${each.value.az}-${each.value.seq}"
  }
}

resource "aws_subnet" "isolated" {
  for_each = local.isolated_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.key
  availability_zone = each.value.az

  tags = {
    Name = "${var.name}-isolated-${each.value.az}-${each.value.seq}"
  }
}
