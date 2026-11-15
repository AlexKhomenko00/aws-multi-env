resource "aws_cloudwatch_log_group" "container_insights" {
  name              = "/aws/ecs/containerinsights/${module.label.id}/performance"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "this" {
  name = module.label.id

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  depends_on = [aws_cloudwatch_log_group.container_insights]
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
}
