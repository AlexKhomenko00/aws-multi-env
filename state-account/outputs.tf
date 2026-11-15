output "bucket_name" {
  value = module.tfstate_bucket.bucket_name
}

output "backend_config" {
  value = "bucket=${module.tfstate_bucket.bucket_name}"
}
