module "tfstate_bucket" {
  source = "../modules/tfstate-bucket"

  namespace   = "acme"
  environment = "euc1"
  stage       = "org"
}

moved {
  from = aws_s3_bucket.org_state
  to   = module.tfstate_bucket.aws_s3_bucket.this
}

moved {
  from = aws_s3_bucket_versioning.org_state
  to   = module.tfstate_bucket.aws_s3_bucket_versioning.this
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.org_state
  to   = module.tfstate_bucket.aws_s3_bucket_server_side_encryption_configuration.this
}

moved {
  from = aws_s3_bucket_public_access_block.org_state
  to   = module.tfstate_bucket.aws_s3_bucket_public_access_block.this
}
