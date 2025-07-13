variable "location" {
  description = "value for the location of the resources"
  type        = string
  # The default value is set to "East US" for Azure resources.
  # You can change this to any other Azure region as per your requirement.
  # For example, "West Europe", "Central US", etc.
  # Refer to the Azure documentation for a list of available regions.
  # https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/azure-regions
  default = "East US"
}

variable "common_tags" {
  type = map(string)
  default = {
    Environment = "Prod"
    Project     = "Billing System"
    Owner       = "DevOps Team"
  }
}