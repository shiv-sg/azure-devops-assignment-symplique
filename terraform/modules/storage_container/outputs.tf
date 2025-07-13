output "name" {
  description = "The name of the storage container."
  value       = azurerm_storage_container.this.name
}

output "storage_account_name" {
  description = "The name of the storage account where the container is located."
  value       = azurerm_storage_container.this.storage_account_name
}

output "access_type" {
  description = "The access type for the storage container."
  value       = azurerm_storage_container.this.container_access_type
}
