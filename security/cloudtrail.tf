module "label_trail" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context = module.label.context
  stage   = "org"
  name    = "trail"
}

locals {
  management_account_id = data.aws_organizations_organization.this.master_account_id
  trail_arn             = "arn:aws:cloudtrail:${data.aws_region.current.region}:${local.management_account_id}:trail/${module.label_trail.id}"
}

module "label_cloudtrail_bucket" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context         = module.label.context
  name            = "cloudtrail"
  label_order     = ["namespace", "stage", "name"]
  id_length_limit = 34
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket              = format("%s-%s-%s-an", module.label_cloudtrail_bucket.id, local.security_account_id, data.aws_region.current.region)
  bucket_namespace    = "account-regional"
  object_lock_enabled = true
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = 30
    }
  }

  depends_on = [aws_s3_bucket_versioning.cloudtrail]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = local.trail_arn
          }
        }
      },
      # Only used if the trail is ever changed from an org trail to a management-only one.
      # https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html#org-trail-bucket-policy
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${local.management_account_id}/*"
        Condition = {
          StringEquals = {
            "aws:SourceArn" = local.trail_arn
          }
        }
      },
      {
        Sid       = "AWSCloudTrailOrganizationWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_organizations_organization.this.id}/*"
        Condition = {
          StringEquals = {
            "aws:SourceArn" = local.trail_arn
          }
        }
      },
    ]
  })
}

resource "aws_cloudtrail" "org" {
  provider = aws.management

  name                          = module.label_trail.id
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  is_organization_trail         = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  include_global_service_events = true

  depends_on = [
    aws_s3_bucket_policy.cloudtrail,
    aws_s3_bucket_object_lock_configuration.cloudtrail,
  ]
}
