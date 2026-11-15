output "service_arn" {
  description = "ARN of the ECS service."
  value       = aws_ecs_service.this.arn
}

output "task_definition_arn" {
  description = "ARN of the (latest) task definition revision."
  value       = aws_ecs_task_definition.this.arn
}

output "log_group_name" {
  description = "CloudWatch log group name the containers ship logs to, whether created by this module or elsewhere."
  value       = local.log_group_name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN. Null when create_cloudwatch_log_group is false - the caller owns that log group and already has its ARN. Otherwise, wire this into the execution role's logs:PutLogEvents policy."
  value       = try(aws_cloudwatch_log_group.this[0].arn, null)
}

output "service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.this.name
}
