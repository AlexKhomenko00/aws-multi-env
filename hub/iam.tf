resource "aws_iam_role" "tailscale_router" {
  name = module.label_tailscale_router.id

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

module "label_tailscale_sts_token" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.label.context
  name    = "get-web-identity-token"
}

resource "aws_iam_role_policy" "tailscale_sts_token" {
  name = module.label_tailscale_sts_token.id
  role = aws_iam_role.tailscale_router.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:GetWebIdentityToken"
        Resource = "*"
        Condition = {
          "ForAnyValue:StringEquals" = {
            "sts:IdentityTokenAudience" = tailscale_federated_identity.hub_router.audience
          }
          NumericLessThanEquals = {
            "sts:DurationSeconds" = "300"
          }
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "tailscale_router" {
  name = module.label_tailscale_router.id
  role = aws_iam_role.tailscale_router.name
}
