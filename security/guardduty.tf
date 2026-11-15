locals {
  security_account_id = data.aws_ssm_parameter.security_account_id.insecure_value

  guardduty_features = {
    S3_DATA_EVENTS         = { enabled = true }
    RDS_LOGIN_EVENTS       = { enabled = true }
    EKS_AUDIT_LOGS         = { enabled = false }
    EBS_MALWARE_PROTECTION = { enabled = false }
    LAMBDA_NETWORK_LOGS    = { enabled = false }
    AI_PROTECTION          = { enabled = false }

    RUNTIME_MONITORING = {
      enabled = true
      additional = {
        ECS_FARGATE_AGENT_MANAGEMENT = true
        EKS_ADDON_MANAGEMENT         = false
        EC2_AGENT_MANAGEMENT         = false
      }
    }
  }
}

resource "aws_organizations_aws_service_access" "guardduty" {
  provider = aws.management

  service_principal = "guardduty.amazonaws.com"
}

resource "aws_guardduty_detector" "security" {}

resource "aws_guardduty_detector_feature" "security" {
  for_each = local.guardduty_features

  detector_id = aws_guardduty_detector.security.id
  name        = each.key
  status      = each.value.enabled ? "ENABLED" : "DISABLED"

  dynamic "additional_configuration" {
    for_each = try(each.value.additional, {})

    content {
      name   = additional_configuration.key
      status = additional_configuration.value ? "ENABLED" : "DISABLED"
    }
  }
}

resource "aws_guardduty_organization_admin_account" "security" {
  provider = aws.management

  admin_account_id = local.security_account_id

  depends_on = [
    aws_organizations_aws_service_access.guardduty,
    aws_guardduty_detector_feature.security,
  ]
}

resource "aws_guardduty_organization_configuration" "this" {
  detector_id                      = aws_guardduty_detector.security.id
  auto_enable_organization_members = "ALL"

  depends_on = [aws_guardduty_organization_admin_account.security]
}

resource "aws_guardduty_organization_configuration_feature" "this" {
  for_each = local.guardduty_features

  detector_id = aws_guardduty_detector.security.id
  name        = each.key
  auto_enable = each.value.enabled ? "ALL" : "NONE"

  dynamic "additional_configuration" {
    for_each = try(each.value.additional, {})

    content {
      name        = additional_configuration.key
      auto_enable = additional_configuration.value ? "ALL" : "NONE"
    }
  }

  depends_on = [aws_guardduty_organization_configuration.this]
}
