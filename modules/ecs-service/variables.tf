variable "name" {
  description = "Base name for the task family, the service, and (unless overridden) the log group."
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster this service runs on. Created externally - this module never owns a cluster."
  type        = string
}

variable "capacity_provider_strategy" {
  description = "FARGATE/FARGATE_SPOT mix. Default: 100% standard Fargate, no Spot. The cluster must have these capacity providers associated (aws_ecs_cluster_capacity_providers) - this module never owns the cluster."
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = optional(number)
  }))
  default = [
    { capacity_provider = "FARGATE", weight = 1 }
  ]
}

variable "region" {
  description = "AWS region to deploy into. Null uses the provider's own configured region."
  type        = string
  default     = null
}

variable "desired_count" {
  description = "Number of task copies the service keeps running."
  type        = number
}

variable "cpu" {
  description = "Task-level vCPU units (Fargate's fixed cpu/memory combinations apply)."
  type        = string
}

variable "memory" {
  description = "Task-level memory, MiB."
  type        = string
}

variable "execution_role_arn" {
  description = "Role the ECS agent assumes to pull the image and ship logs - not the app's own permissions."
  type        = string
}

variable "task_role_arn" {
  description = "Role the running application code assumes. Null if the app needs no AWS permissions of its own."
  type        = string
  default     = null
}

variable "containers" {
  description = "Containers in the task - the main app plus any sidecars. At least one must be essential."
  type = list(object({
    name      = string
    image     = string
    essential = optional(bool, true)
    cpu       = optional(number)
    memory    = optional(number)
    ports = optional(list(object({
      container_port = number
      protocol       = optional(string, "tcp")
    })), [])
    user        = optional(string)
    environment = optional(map(string), {})
    secrets     = optional(map(string), {})
    health_check = optional(object({
      command      = list(string)
      interval     = optional(number, 30)
      timeout      = optional(number, 5)
      retries      = optional(number, 3)
      start_period = optional(number, 0)
    }))
  }))
}

variable "subnet_ids" {
  description = "Subnets the task's ENI launches into."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups attached to the task's ENI. Created externally, same pattern as modules/vpc's workload SGs."
  type        = list(string)
}

variable "load_balancers" {
  description = "ALB/NLB target group registrations for this service. Empty list for a service with no load balancer (e.g. Catalog, service-discovery only). Each container_port must match that container's declared port in var.containers."
  type = list(object({
    target_group_arn = string
    container_name   = string
    container_port   = number
  }))
  default = []
}

variable "service_registry_arn" {
  description = "ARN of the aws_service_discovery_service (Cloud Map) to register tasks into. Null for a service with no service discovery. Created externally in staging."
  type        = string
  default     = null
}

variable "create_cloudwatch_log_group" {
  description = "Whether this module creates the container's log group. False to point at one created elsewhere."
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "CloudWatch log group retention. Only used when create_cloudwatch_log_group is true."
  type        = number
  default     = 30
}

variable "deployment_maximum_percent" {
  description = "Upper bound on running task count, as % of desired_count, during a rolling deployment."
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower bound on running task count, as % of desired_count, during a rolling deployment."
  type        = number
  default     = 100
}

variable "health_check_grace_period_seconds" {
  description = "Time to ignore failing load balancer/service-discovery health checks after a task starts, before they count against it."
  type        = number
  default     = 0
}

variable "platform_version" {
  description = "Fargate platform version."
  type        = string
  default     = "LATEST"
}

variable "tags" {
  description = "Tags applied to the module's resources."
  type        = map(string)
  default     = {}
}

variable "autoscaling" {
  description = "Target-tracking autoscaling on the service's desired count. Null disables it. min/max bound the count; each *_target is an average utilization % to hold (null skips that metric). Cooldowns are seconds."
  type = object({
    min_capacity       = number
    max_capacity       = number
    cpu_target         = optional(number, 70)
    memory_target      = optional(number)
    scale_in_cooldown  = optional(number, 300)
    scale_out_cooldown = optional(number, 60)
  })
  default = null
}
