output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_arn" {
  value = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  value = aws_vpc.this.cidr_block
}

output "public_subnets" {
  description = "Map of public subnet CIDR => { id, az }."
  value       = { for cidr, s in aws_subnet.public : cidr => { id = s.id, az = s.availability_zone } }
}

output "private_subnets" {
  description = "Map of private subnet CIDR => { id, az }."
  value       = { for cidr, s in aws_subnet.private : cidr => { id = s.id, az = s.availability_zone } }
}

output "isolated_subnets" {
  description = "Map of isolated subnet CIDR => { id, az }."
  value       = { for cidr, s in aws_subnet.isolated : cidr => { id = s.id, az = s.availability_zone } }
}

output "public_subnet_ids" {
  value = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  value = values(aws_subnet.private)[*].id
}

output "isolated_subnet_ids" {
  value = values(aws_subnet.isolated)[*].id
}

output "internet_gateway_id" {
  value = try(aws_internet_gateway.this[0].id, null)
}

output "public_route_table_id" {
  value = try(aws_route_table.public[0].id, null)
}

output "private_route_table_ids" {
  description = "Map of NAT-gateway AZ => private route table id."
  value       = { for az, rt in aws_route_table.private : az => rt.id }
}

output "isolated_route_table_id" {
  value = try(aws_route_table.isolated[0].id, null)
}

output "nat_gateway_ids" {
  description = "Map of AZ => NAT gateway id."
  value       = { for az, nat in aws_nat_gateway.this : az => nat.id }
}

output "nat_gateway_public_ips" {
  description = "Map of AZ => NAT gateway public IP."
  value       = { for az, eip in aws_eip.nat : az => eip.public_ip }
}

output "default_security_group_id" {
  value = aws_default_security_group.this.id
}

output "flow_log_group_name" {
  value = try(aws_cloudwatch_log_group.flow_logs[0].name, null)
}

output "flow_log_group_arn" {
  value = try(aws_cloudwatch_log_group.flow_logs[0].arn, null)
}

output "endpoint_ids" {
  description = "VPC endpoint IDs by service short name."
  value       = { for k, e in aws_vpc_endpoint.this : k => e.id }
}

output "endpoint_security_group_ids" {
  description = "Security group per Interface endpoint, by service short name. They have no rules; callers add ingress from whatever should reach each endpoint."
  value       = { for k, sg in aws_security_group.endpoints : k => sg.id }
}
