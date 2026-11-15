resource "aws_guardduty_detector" "management" {
  provider = aws.management
}

resource "aws_guardduty_detector_feature" "management" {
  provider = aws.management
  for_each = local.guardduty_features

  detector_id = aws_guardduty_detector.management.id
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

resource "aws_guardduty_member" "management" {
  detector_id = aws_guardduty_detector.security.id
  account_id  = data.aws_organizations_organization.this.master_account_id
  email       = data.aws_organizations_organization.this.master_account_email

  depends_on = [
    aws_guardduty_organization_configuration_feature.this,
    aws_guardduty_detector_feature.management,
  ]
}
