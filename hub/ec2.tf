data "aws_ami" "al2023_arm" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

module "label_tailscale_router" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.label.context
  name    = "tailscale-router"
}

resource "aws_instance" "tailscale_router" {
  ami                    = data.aws_ami.al2023_arm.id
  instance_type          = var.instance_type
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.tailscale_router.id]
  iam_instance_profile   = aws_iam_instance_profile.tailscale_router.name

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
  }

  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    advertised_routes   = local.advertised_routes
    hub_router_tag      = local.hub_router_tag
    tailscale_client_id = tailscale_federated_identity.hub_router.id
    tailscale_audience  = tailscale_federated_identity.hub_router.audience
  })

  tags = {
    Name = module.label_tailscale_router.id
  }

  depends_on = [aws_iam_role_policy.tailscale_sts_token]
}
