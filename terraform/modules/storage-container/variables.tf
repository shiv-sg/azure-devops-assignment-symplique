variable "name" {
  description = "The name of the storage container."
  type        = string
}

variable "storage_account_name" {
  description = "The name of the storage account where the container will be created."
  type        = string
}

variable "access_type" {
  description = "The access type for the storage container."
  type        = string
  default     = "private"
}