locals {
  cluster_name = element(split("/", var.cluster_arn), 1)

  autoscaling_metrics = var.autoscaling == null ? {} : {
    for k, v in {
      cpu    = { metric = "ECSServiceAverageCPUUtilization", target = var.autoscaling.cpu_target }
      memory = { metric = "ECSServiceAverageMemoryUtilization", target = var.autoscaling.memory_target }
    } : k => v if v.target != null
  }
}

resource "aws_appautoscaling_target" "this" {
  count = var.autoscaling == null ? 0 : 1

  region             = var.region
  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  resource_id        = "service/${local.cluster_name}/${aws_ecs_service.this.name}"
  min_capacity       = var.autoscaling.min_capacity
  max_capacity       = var.autoscaling.max_capacity

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.autoscaling.min_capacity <= var.desired_count && var.desired_count <= var.autoscaling.max_capacity
      error_message = "desired_count must sit within autoscaling min_capacity..max_capacity."
    }
  }
}

resource "aws_appautoscaling_policy" "this" {
  for_each = local.autoscaling_metrics

  region             = var.region
  name               = "${var.name}-${each.key}"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  resource_id        = aws_appautoscaling_target.this[0].resource_id

  target_tracking_scaling_policy_configuration {
    target_value       = each.value.target
    scale_in_cooldown  = var.autoscaling.scale_in_cooldown
    scale_out_cooldown = var.autoscaling.scale_out_cooldown

    predefined_metric_specification {
      predefined_metric_type = each.value.metric
    }
  }
}
