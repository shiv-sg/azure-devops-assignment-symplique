provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-billing-system"
  location = "East US"
}

resource "random_id" "unique" {
  byte_length = 4
}

# Storage Account
module "storage_account" {
  source              = "./modules/storage_account"
  name                = "billingstorage${random_id.unique.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.common_tags
}

# Blob Containers
module "archived_container" {
  source               = "./modules/storage-container"
  name                 = "archived"
  storage_account_name = module.storage_account.name
  access_type          = "private"
}

module "logs_container" {
  source               = "./modules/storage-container"
  name                 = "logs"
  storage_account_name = module.storage_account.name
  access_type          = "private"
}

# Application Insights
module "application_insights" {
  source              = "./modules/application-insights"
  name                = "billing-insights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  tags                = var.common_tags
}

# Function App - Retrieval API (HTTP Trigger)
module "billing_retrieval_function_app" {
  source                     = "./modules/function-app"
  name                       = "billing-retrieval-api"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  storage_account_name       = module.storage_account.name
  storage_account_access_key = module.storage_account.primary_access_key
  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = module.application_insights.instrumentation_key
    AzureWebJobsStorage            = module.storage_account.primary_connection_string
    BLOB_CONTAINER_ARCHIVE         = module.archived_container.name
    BLOB_CONTAINER_LOGS            = module.logs_container.name
  }

  tags = var.common_tags
}

# Function App - Archiver Job (Timer Trigger)
module "billing_archiver_function_app" {
  source                     = "./modules/function-app"
  name                       = "billing-archiver-job"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  storage_account_name       = module.storage_account.name
  storage_account_access_key = module.storage_account.primary_access_key
  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = module.application_insights.instrumentation_key
    AzureWebJobsStorage            = module.storage_account.primary_connection_string
    BLOB_CONTAINER_ARCHIVE         = module.archived_container.name
    BLOB_CONTAINER_LOGS            = module.logs_container.name
    ARCHIVAL_SCHEDULE_CRON         = "0 0 2 * * *" # daily 2am UTC
  }

  tags = var.common_tags
}
