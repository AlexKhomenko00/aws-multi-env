locals {
  containers_by_name = { for c in var.containers : c.name => c }
}

resource "aws_ecs_service" "this" {
  region           = var.region
  name             = var.name
  cluster          = var.cluster_arn
  task_definition  = aws_ecs_task_definition.this.arn
  desired_count    = var.desired_count
  platform_version = var.platform_version

  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = capacity_provider_strategy.value.base
    }
  }

  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.load_balancers
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  dynamic "service_registries" {
    for_each = var.service_registry_arn != null ? [1] : []
    content {
      registry_arn = var.service_registry_arn
    }
  }

  tags = var.tags

  lifecycle {
    # Scale belongs to autoscaling and image rollouts to a future deploy pipeline, not Terraform.
    ignore_changes = [desired_count, task_definition]

    precondition {
      condition = alltrue([
        for lb in var.load_balancers : contains(keys(local.containers_by_name), lb.container_name)
      ])
      error_message = "Each load_balancers[].container_name must match a name in var.containers."
    }
    precondition {
      condition = alltrue([
        for lb in var.load_balancers : contains(
          [for p in try(local.containers_by_name[lb.container_name].ports, []) : p.container_port],
          lb.container_port
        )
      ])
      error_message = "Each load_balancers[].container_port must match one of that container's declared ports in var.containers."
    }
  }
}
