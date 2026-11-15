locals {
  public_subnets = {
    for idx, cidr in var.public_subnet_cidrs :
    cidr => {
      az  = var.azs[idx % length(var.azs)]
      seq = floor(idx / length(var.azs)) + 1
    }
  }

  private_subnets = {
    for idx, cidr in var.private_subnet_cidrs :
    cidr => {
      az  = var.azs[idx % length(var.azs)]
      seq = floor(idx / length(var.azs)) + 1
    }
  }

  isolated_subnets = {
    for idx, cidr in var.isolated_subnet_cidrs :
    cidr => {
      az  = var.azs[idx % length(var.azs)]
      seq = floor(idx / length(var.azs)) + 1
    }
  }

  private_azs = distinct([for cidr, s in local.private_subnets : s.az])

  nat_gateway_azs = var.single_nat_gateway ? slice(local.private_azs, 0, length(local.private_azs) > 0 ? 1 : 0) : local.private_azs

  private_route_target_az_by_az = {
    for az in local.private_azs :
    az => var.single_nat_gateway ? local.nat_gateway_azs[0] : az
  }

  public_subnet_cidr_by_az = {
    for az in distinct([for cidr, s in local.public_subnets : s.az]) :
    az => [for cidr, s in local.public_subnets : cidr if s.az == az][0]
  }
}
