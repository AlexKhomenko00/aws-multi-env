locals {
  log_group_name = "/ecs/${var.name}"

  container_definitions_raw = [
    for c in var.containers : {
      name      = c.name
      image     = c.image
      essential = c.essential
      cpu       = c.cpu
      memory    = c.memory
      user      = c.user

      portMappings = length(c.ports) > 0 ? [
        for p in c.ports : {
          containerPort = p.container_port
          protocol      = p.protocol
        }
      ] : null

      environment = length(c.environment) > 0 ? [for k, v in c.environment : { name = k, value = v }] : null
      secrets     = length(c.secrets) > 0 ? [for k, v in c.secrets : { name = k, valueFrom = v }] : null

      healthCheck = c.health_check == null ? null : {
        command     = c.health_check.command
        interval    = c.health_check.interval
        timeout     = c.health_check.timeout
        retries     = c.health_check.retries
        startPeriod = c.health_check.start_period
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = coalesce(var.region, data.aws_region.current.region)
          awslogs-group         = var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.this[0].name : local.log_group_name
          awslogs-stream-prefix = c.name
        }
      }
    }
  ]

  container_definitions = [
    for c in local.container_definitions_raw : { for k, v in c : k => v if v != null }
  ]
}

resource "aws_cloudwatch_log_group" "this" {
  count = var.create_cloudwatch_log_group ? 1 : 0

  region            = var.region
  name              = local.log_group_name
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

resource "aws_ecs_task_definition" "this" {
  region                   = var.region
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode(local.container_definitions)

  tags = var.tags

  lifecycle {
    precondition {
      condition     = anytrue([for c in var.containers : c.essential])
      error_message = "At least one container in var.containers must be essential."
    }
  }
}
