locals {
  account_ids = zipmap(
    [for n in data.aws_ssm_parameters_by_path.accounts.names : basename(n)],
    nonsensitive(data.aws_ssm_parameters_by_path.accounts.values),
  )

  member_account_ids = { for name, id in local.account_ids : name => id if name != "tfstate" }
}

module "tfstate_bucket" {
  source = "../modules/tfstate-bucket"

  providers = {
    aws = aws.tfstate
  }

  namespace   = "acme"
  environment = "euc1"
  stage       = "tfstate"
}

resource "aws_s3_bucket_policy" "tfstate" {
  provider = aws.tfstate

  bucket = module.tfstate_bucket.bucket_name
  policy = data.aws_iam_policy_document.tfstate.json
}
