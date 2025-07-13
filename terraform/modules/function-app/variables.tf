variable "name" {
  type        = string
  description = "The name of the Function App."
}

variable "location" {
  type        = string
  description = "The Azure region where the Function App will be created."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where the Function App will be created."
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account where the Function App will be created."
}

variable "storage_account_access_key" {
  type        = string
  description = "The access key for the storage account."
}

variable "app_settings" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "identity_type" {
  description = "The type of identity to use for the Function App."
  type        = string
  default     = "SystemAssigned"
}

variable "version" {
  description = "The version of the Azure Functions runtime to use."
  type        = string
  default     = "~4"
}