module "network_plan" {
  source = "../modules/network-plan"
}

module "vpc" {
  source = "../modules/vpc"

  name     = module.label.id
  vpc_cidr = local.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnet_cidrs   = [cidrsubnet(local.vpc_cidr, 8, 1), cidrsubnet(local.vpc_cidr, 8, 2)]
  private_subnet_cidrs  = [cidrsubnet(local.vpc_cidr, 8, 11)]
  isolated_subnet_cidrs = [cidrsubnet(local.vpc_cidr, 8, 21), cidrsubnet(local.vpc_cidr, 8, 22)]

  single_nat_gateway = true
}
