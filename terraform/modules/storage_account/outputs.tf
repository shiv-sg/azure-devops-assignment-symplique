output "name" {
  value = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_access_key" {
  value = azurerm_storage_account.this.primary_access_key
}

output "primary_connection_string" {
  value = azurerm_storage_account.this.primary_connection_string
}