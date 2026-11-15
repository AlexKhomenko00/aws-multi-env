locals {
  vpc_cidrs = {
    prod    = "10.0.0.0/16"
    staging = "10.4.0.0/16"
    hub     = "10.16.0.0/16"
  }

  supernet = "10.0.0.0/8"
}

output "vpc_cidrs" {
  value = local.vpc_cidrs
}

output "supernet" {
  value = local.supernet
}
