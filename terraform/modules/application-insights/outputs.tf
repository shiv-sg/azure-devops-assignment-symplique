output "name" {
  description = "The name of the Application Insights resource."
  value       = azurerm_application_insights.this.name
}

output "instrumentation_key" {
  value = azurerm_application_insights.this.instrumentation_key
}

output "application_type" {
  description = "The type of application monitored by Application Insights."
  value       = azurerm_application_insights.this.application_type
}