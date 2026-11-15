module "label_ui" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context         = module.label.context
  name            = "ui"
  id_length_limit = 32
}

module "ecs_service_ui" {
  source = "../modules/ecs-service"

  name          = module.label_ui.id
  cluster_arn   = aws_ecs_cluster.this.arn
  desired_count = 1
  cpu           = "256"
  memory        = "1024"

  health_check_grace_period_seconds = 180

  capacity_provider_strategy = [
    { capacity_provider = "FARGATE", weight = 1, base = 1 },
    { capacity_provider = "FARGATE_SPOT", weight = 4 }
  ]

  execution_role_arn = aws_iam_role.ui_execution.arn

  containers = [
    {
      name  = local.services.ui.name
      image = "${aws_ecr_repository.this["ui"].repository_url}:1.6.2"

      ports = [
        { container_port = local.services.ui.port }
      ]

      environment = {
        RETAIL_UI_ENDPOINTS_CATALOG = "http://${aws_service_discovery_service.catalog.name}.${aws_service_discovery_private_dns_namespace.this.name}:8080"
      }

      health_check = {
        command      = ["CMD-SHELL", "curl -fsS http://localhost:${local.services.ui.port}/actuator/health || exit 1"]
        interval     = 30
        timeout      = 5
        retries      = 3
        start_period = 120
      }
    }
  ]

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.ui.id]

  load_balancers = [
    {
      target_group_arn = aws_lb_target_group.ui.arn
      container_name   = local.services.ui.name
      container_port   = local.services.ui.port
    }
  ]

  depends_on = [
    aws_ecs_cluster_capacity_providers.this,
    aws_lb_listener.http,
    aws_iam_role_policy.ui_execution_logs,
    aws_iam_role_policy.ui_execution_ecr,
    module.vpc,
  ]
}

module "label_catalog" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context         = module.label.context
  name            = "catalog"
  id_length_limit = 63
}

module "ecs_service_catalog" {
  source = "../modules/ecs-service"

  name          = module.label_catalog.id
  cluster_arn   = aws_ecs_cluster.this.arn
  desired_count = 1
  cpu           = "256"
  memory        = "512"

  capacity_provider_strategy = [
    { capacity_provider = "FARGATE", weight = 1, base = 1 },
    { capacity_provider = "FARGATE_SPOT", weight = 4 }
  ]

  execution_role_arn = aws_iam_role.catalog_execution.arn

  containers = [
    {
      name  = "catalog"
      image = "${aws_ecr_repository.this["catalog"].repository_url}:1.6.2"

      ports = [
        { container_port = 8080 }
      ]

      environment = {
        RETAIL_CATALOG_PERSISTENCE_PROVIDER = "mysql"
        RETAIL_CATALOG_PERSISTENCE_ENDPOINT = "${aws_db_instance.catalog.address}:${aws_db_instance.catalog.port}"
        RETAIL_CATALOG_PERSISTENCE_DB_NAME  = aws_db_instance.catalog.db_name
        RETAIL_CATALOG_PERSISTENCE_USER     = aws_db_instance.catalog.username
      }

      secrets = {
        RETAIL_CATALOG_PERSISTENCE_PASSWORD = "${aws_db_instance.catalog.master_user_secret[0].secret_arn}:password::"
      }

      health_check = {
        command      = ["CMD-SHELL", "curl -fsS http://localhost:8080/health || exit 1"]
        interval     = 30
        timeout      = 5
        retries      = 3
        start_period = 30
      }
    }
  ]

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.catalog.id]

  service_registry_arn = aws_service_discovery_service.catalog.arn

  depends_on = [
    aws_ecs_cluster_capacity_providers.this,
    aws_iam_role_policy.catalog_execution_logs,
    aws_iam_role_policy.catalog_execution_db_secret,
    aws_iam_role_policy.catalog_execution_ecr,
    module.vpc,
  ]
}
