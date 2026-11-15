output "account_ids" {
  description = "Member account IDs by name. Other folders read them from the shared SSM parameters (account_parameters.tf), not from here."
  value       = local.account_ids
}
