provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "rg-billing-system"
  location = "East US"
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "billingstore${random_id.unique.hex}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "random_id" "unique" {
  byte_length = 4
}

# Blob Containers
resource "azurerm_storage_container" "archived" {
  name                  = "archived"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# App Service Plan
resource "azurerm_app_service_plan" "main" {
  name                = "billing-functions-plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "billing-insights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
}

# Function App - Retrieval API (HTTP Trigger)
resource "azurerm_function_app" "retrieval_api" {
  name                       = "billing-retrieval-api"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  app_service_plan_id        = azurerm_app_service_plan.main.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  version                    = "~4"

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME    = "python"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.main.instrumentation_key
    AzureWebJobsStorage         = azurerm_storage_account.main.primary_connection_string
    BLOB_CONTAINER_ARCHIVE      = azurerm_storage_container.archived.name
    BLOB_CONTAINER_LOGS         = azurerm_storage_container.logs.name
  }
}

# Function App - Archiver Job (Timer Trigger)
resource "azurerm_function_app" "archiver_job" {
  name                       = "billing-archiver-job"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  app_service_plan_id        = azurerm_app_service_plan.main.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  version                    = "~4"

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME    = "python"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.main.instrumentation_key
    AzureWebJobsStorage         = azurerm_storage_account.main.primary_connection_string
    BLOB_CONTAINER_ARCHIVE      = azurerm_storage_container.archived.name
    BLOB_CONTAINER_LOGS         = azurerm_storage_container.logs.name
    ARCHIVAL_SCHEDULE_CRON      = "0 0 2 * * *"  # daily 2am UTC
  }
}
