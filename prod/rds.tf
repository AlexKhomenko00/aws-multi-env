resource "aws_db_subnet_group" "catalog" {
  name       = module.label_catalog.id
  subnet_ids = module.vpc.isolated_subnet_ids
}

resource "aws_db_instance" "catalog" {
  identifier     = module.label_catalog.id
  engine         = "mysql"
  engine_version = "8.4"
  instance_class = "db.t4g.small"

  engine_lifecycle_support = "open-source-rds-extended-support-disabled"

  allocated_storage = 20
  storage_encrypted = true

  db_name  = "catalogdb"
  username = "catalog_user"

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.catalog.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                = true
  publicly_accessible     = false
  backup_retention_period = 7
  copy_tags_to_snapshot   = true
  skip_final_snapshot     = true
}
