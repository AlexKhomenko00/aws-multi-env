resource "aws_security_group" "tailscale_router" {
  name   = module.label_tailscale_router.id
  vpc_id = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
