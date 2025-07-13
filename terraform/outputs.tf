output "retrieval_function_url" {
  value = module.billing_retrieval_function_app.default_hostname
}

output "archival_function_url" {
  value = module.billing_archiver_function_app.default_hostname
}

output "storage_account_name" {
  value = module.storage_account.name
}
