output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "tailscale_router_instance_id" {
  value = aws_instance.tailscale_router.id
}

output "tailscale_router_public_ip" {
  value = aws_instance.tailscale_router.public_ip
}

output "transit_gateway_id" {
  value = aws_ec2_transit_gateway.this.id
}
