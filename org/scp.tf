module "label_deny_leave_org" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.label.context
  name    = "deny-leave-org"
}

resource "aws_organizations_policy" "deny_leave_org" {
  name = module.label_deny_leave_org.id
  type = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyLeaveOrganization"
        Effect   = "Deny"
        Action   = "organizations:LeaveOrganization"
        Resource = "*"
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "deny_leave_org" {
  policy_id = aws_organizations_policy.deny_leave_org.id
  target_id = data.aws_organizations_organization.this.roots[0].id
}

module "label_deny_cloudtrail_tampering" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.label.context
  name    = "deny-cloudtrail-tampering"
}

resource "aws_organizations_policy" "deny_cloudtrail_tampering" {
  name = module.label_deny_cloudtrail_tampering.id
  type = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyCloudTrailTampering"
        Effect = "Deny"
        Action = [
          "cloudtrail:StopLogging",
          "cloudtrail:DeleteTrail",
          "cloudtrail:UpdateTrail",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "deny_cloudtrail_tampering" {
  policy_id = aws_organizations_policy.deny_cloudtrail_tampering.id
  target_id = data.aws_organizations_organization.this.roots[0].id
}

module "label_deny_outside_approved_regions" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.label.context
  name    = "deny-outside-approved-regions"
}

resource "aws_organizations_policy" "deny_outside_approved_regions" {
  name = module.label_deny_outside_approved_regions.id
  type = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyAllOutsideApprovedRegions"
        Effect = "Deny"
        NotAction = [
          "a4b:*",
          "acm:*",
          "aws-marketplace-management:*",
          "aws-marketplace:*",
          "aws-portal:*",
          "budgets:*",
          "ce:*",
          "chime:*",
          "cloudfront:*",
          "config:*",
          "cur:*",
          "directconnect:*",
          "ec2:DescribeRegions",
          "ec2:DescribeTransitGateways",
          "ec2:DescribeVpnGateways",
          "fms:*",
          "globalaccelerator:*",
          "health:*",
          "iam:*",
          "identitystore:*",
          "importexport:*",
          "kms:*",
          "mobileanalytics:*",
          "networkmanager:*",
          "organizations:*",
          "pricing:*",
          "route53:*",
          "route53domains:*",
          "s3:GetAccountPublic*",
          "s3:ListAllMyBuckets",
          "s3:PutAccountPublic*",
          "shield:*",
          "sso:*",
          "sts:*",
          "support:*",
          "trustedadvisor:*",
          "waf-regional:*",
          "waf:*",
          "wafv2:*",
          "wellarchitected:*",
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = [
              "eu-central-1",
              "us-east-1",
            ]
          }
        }
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "deny_outside_approved_regions" {
  policy_id = aws_organizations_policy.deny_outside_approved_regions.id
  target_id = data.aws_organizations_organization.this.roots[0].id
}

module "label_deny_guardduty_changes" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.label.context
  name    = "deny-guardduty-changes"
}

resource "aws_organizations_policy" "deny_guardduty_changes" {
  name = module.label_deny_guardduty_changes.id
  type = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyGuardDutyChangesExceptAutomation"
        Effect = "Deny"
        Action = [
          "guardduty:DeclineInvitations",
          "guardduty:Disassociate*",
          "guardduty:DeleteDetector",
          "guardduty:DeleteInvitations",
          "guardduty:DeleteIPSet",
          "guardduty:DeleteMembers",
          "guardduty:DeleteThreatIntelSet",
          "guardduty:StopMonitoringMembers",
          "guardduty:UpdateDetector",
        ]
        Resource = "*"
        Condition = {
          ArnNotLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:role/OrganizationAccountAccessRole"
          }
        }
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "deny_guardduty_changes" {
  policy_id = aws_organizations_policy.deny_guardduty_changes.id
  target_id = data.aws_organizations_organization.this.roots[0].id
}
