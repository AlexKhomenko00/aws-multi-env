module "network_plan" {
  source = "../modules/network-plan"
}

module "vpc" {
  source = "../modules/vpc"

  name     = module.label.id
  vpc_cidr = local.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  public_subnet_cidrs   = [for i in [1, 2, 3] : cidrsubnet(local.vpc_cidr, 8, i)]
  private_subnet_cidrs  = [for i in [11, 12, 13] : cidrsubnet(local.vpc_cidr, 8, i)]
  isolated_subnet_cidrs = [for i in [21, 22, 23] : cidrsubnet(local.vpc_cidr, 8, i)]

  single_nat_gateway = false
}
