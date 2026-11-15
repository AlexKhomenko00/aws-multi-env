data "aws_ssm_parameters_by_path" "accounts" {
  path = "/org/accounts"
}

data "aws_iam_policy_document" "tfstate" {
  dynamic "statement" {
    for_each = local.member_account_ids

    content {
      sid       = "${title(statement.key)}ListOwnPrefix"
      actions   = ["s3:ListBucket"]
      resources = [module.tfstate_bucket.bucket_arn]

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value}:root"]
      }

      condition {
        test     = "StringLike"
        variable = "s3:prefix"
        values   = ["${statement.key}/*"]
      }
    }
  }

  dynamic "statement" {
    for_each = local.member_account_ids

    content {
      sid       = "${title(statement.key)}ReadWriteState"
      actions   = ["s3:GetObject", "s3:PutObject"]
      resources = ["${module.tfstate_bucket.bucket_arn}/${statement.key}/terraform.tfstate"]

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value}:root"]
      }
    }
  }

  dynamic "statement" {
    for_each = local.member_account_ids

    content {
      sid       = "${title(statement.key)}Lock"
      actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
      resources = ["${module.tfstate_bucket.bucket_arn}/${statement.key}/terraform.tfstate.tflock"]

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value}:root"]
      }
    }
  }

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [module.tfstate_bucket.bucket_arn, "${module.tfstate_bucket.bucket_arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}
