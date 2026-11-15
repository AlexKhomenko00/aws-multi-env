module "network_plan" {
  source = "../modules/network-plan"
}

module "vpc" {
  source = "../modules/vpc"

  name     = module.label.id
  vpc_cidr = local.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 1)

  public_subnet_cidrs = [cidrsubnet(local.vpc_cidr, 8, 1)]
}
