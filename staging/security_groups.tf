resource "aws_security_group" "alb" {
  name   = module.label_alb.id
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "ui" {
  name   = module.label_ui.id
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "catalog" {
  name   = module.label_catalog.id
  vpc_id = module.vpc.vpc_id
}

module "label_rds" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.label.context
  name    = "rds"
}

resource "aws_security_group" "rds" {
  name   = module.label_rds.id
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ui" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.ui.id
  ip_protocol                  = "tcp"
  from_port                    = local.services.ui.port
  to_port                      = local.services.ui.port
}

resource "aws_vpc_security_group_ingress_rule" "ui_from_alb" {
  security_group_id            = aws_security_group.ui.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = local.services.ui.port
  to_port                      = local.services.ui.port
}

resource "aws_vpc_security_group_egress_rule" "ui_to_catalog" {
  security_group_id            = aws_security_group.ui.id
  referenced_security_group_id = aws_security_group.catalog.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

resource "aws_vpc_security_group_ingress_rule" "catalog_from_ui" {
  security_group_id            = aws_security_group.catalog.id
  referenced_security_group_id = aws_security_group.ui.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

resource "aws_vpc_security_group_egress_rule" "catalog_to_rds" {
  security_group_id            = aws_security_group.catalog.id
  referenced_security_group_id = aws_security_group.rds.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_catalog" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.catalog.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_hub" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = module.network_plan.vpc_cidrs["hub"]
  ip_protocol       = "tcp"
  from_port         = 3306
  to_port           = 3306
}

resource "aws_vpc_security_group_egress_rule" "app_https_out" {
  for_each = { ui = aws_security_group.ui.id, catalog = aws_security_group.catalog.id }

  security_group_id = each.value
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
