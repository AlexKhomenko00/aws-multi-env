locals {
  alert_email       = var.email
  anomaly_alert_usd = var.budget_limit * 0.4
}

module "label_budget" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.label.context
  name    = "monthly-budget"
}

resource "aws_budgets_budget" "org" {
  name         = module.label_budget.id
  budget_type  = "COST"
  limit_amount = var.budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 90
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [local.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [local.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [local.alert_email]
  }
}

module "label_anomaly_monitor" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.label.context
  name    = "service-monitor"
}

resource "aws_ce_anomaly_monitor" "org" {
  name              = module.label_anomaly_monitor.id
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

module "label_anomaly_topic" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.label.context
  name    = "cost-anomaly-alerts"
}

resource "aws_sns_topic" "cost_anomaly" {
  name = module.label_anomaly_topic.id
}

data "aws_iam_policy_document" "cost_anomaly_publish" {
  statement {
    sid       = "AllowCostAnomalyDetectionPublish"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.cost_anomaly.arn]

    principals {
      type        = "Service"
      identifiers = ["costalerts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_organizations_organization.this.master_account_id]
    }
  }
}

resource "aws_sns_topic_policy" "cost_anomaly" {
  arn    = aws_sns_topic.cost_anomaly.arn
  policy = data.aws_iam_policy_document.cost_anomaly_publish.json
}

resource "aws_sns_topic_subscription" "cost_anomaly_email" {
  topic_arn = aws_sns_topic.cost_anomaly.arn
  protocol  = "email"
  endpoint  = local.alert_email
}

module "label_anomaly_subscription" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.label.context
  name    = "anomaly-subscription"
}

resource "aws_ce_anomaly_subscription" "org" {
  name             = module.label_anomaly_subscription.id
  frequency        = "IMMEDIATE"
  monitor_arn_list = [aws_ce_anomaly_monitor.org.arn]

  subscriber {
    type    = "SNS"
    address = aws_sns_topic.cost_anomaly.arn
  }

  depends_on = [aws_sns_topic_policy.cost_anomaly]

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = [tostring(local.anomaly_alert_usd)]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }
}
