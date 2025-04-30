output "retrieval_function_url" {
  value = azurerm_function_app.retrieval_api.default_hostname
}

output "archival_function_url" {
  value = azurerm_function_app.archiver_job.default_hostname
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}
