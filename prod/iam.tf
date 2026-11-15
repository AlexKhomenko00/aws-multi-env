data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

module "label_ui_execution" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context         = module.label_ui.context
  attributes      = ["execution"]
  id_length_limit = 64
}

resource "aws_iam_role" "ui_execution" {
  name               = module.label_ui_execution.id
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

module "label_ui_execution_logs" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context    = module.label_ui_execution.context
  attributes = ["logs"]
}

resource "aws_iam_role_policy" "ui_execution_logs" {
  name = module.label_ui_execution_logs.id
  role = aws_iam_role.ui_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${module.label_ui.id}:*"
    }]
  })
}

module "label_ui_execution_ecr" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context    = module.label_ui_execution.context
  attributes = ["ecr-pull"]
}

resource "aws_iam_role_policy" "ui_execution_ecr" {
  name = module.label_ui_execution_ecr.id
  role = aws_iam_role.ui_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchImportUpstreamImage",
        ]
        Resource = aws_ecr_repository.this["ui"].arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = local.guardduty_agent_repository_arn
      },
    ]
  })
}

module "label_catalog_execution" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context         = module.label_catalog.context
  attributes      = ["execution"]
  id_length_limit = 64
}

resource "aws_iam_role" "catalog_execution" {
  name               = module.label_catalog_execution.id
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

module "label_catalog_execution_logs" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context    = module.label_catalog_execution.context
  attributes = ["logs"]
}

resource "aws_iam_role_policy" "catalog_execution_logs" {
  name = module.label_catalog_execution_logs.id
  role = aws_iam_role.catalog_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${module.label_catalog.id}:*"
    }]
  })
}

module "label_catalog_execution_db_secret" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context    = module.label_catalog_execution.context
  attributes = ["db-secret"]
}

resource "aws_iam_role_policy" "catalog_execution_db_secret" {
  name = module.label_catalog_execution_db_secret.id
  role = aws_iam_role.catalog_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = aws_db_instance.catalog.master_user_secret[0].secret_arn
    }]
  })
}

module "label_catalog_execution_ecr" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context    = module.label_catalog_execution.context
  attributes = ["ecr-pull"]
}

resource "aws_iam_role_policy" "catalog_execution_ecr" {
  name = module.label_catalog_execution_ecr.id
  role = aws_iam_role.catalog_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchImportUpstreamImage",
        ]
        Resource = aws_ecr_repository.this["catalog"].arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = local.guardduty_agent_repository_arn
      },
    ]
  })
}
