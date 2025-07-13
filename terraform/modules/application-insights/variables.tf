variable "name" {
  type        = string
  description = "name of the application insights"
}

variable "location" {
  type        = string
  description = "Azure region where the application insights will be created"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where the application insights will be created"
}

variable "application_type" {
  type        = string
  description = "Type of application monitored by Application Insights"
  default     = "web"
}

variable "tags" {
  type    = map(string)
  default = {}
}