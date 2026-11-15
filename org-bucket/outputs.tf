output "bucket_id" {
  value = module.tfstate_bucket.bucket_name
}

output "bucket_arn" {
  value = module.tfstate_bucket.bucket_arn
}
