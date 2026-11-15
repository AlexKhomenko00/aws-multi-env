resource "aws_iam_outbound_web_identity_federation" "this" {}

resource "tailscale_federated_identity" "hub_router" {
  description = "Hub subnet router"
  issuer      = aws_iam_outbound_web_identity_federation.this.issuer_identifier
  subject     = aws_iam_role.tailscale_router.arn
  scopes      = ["auth_keys"]
  tags        = [local.hub_router_tag]

  depends_on = [tailscale_acl.grants]
}
