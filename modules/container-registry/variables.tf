variable "name" {
  type = string
}

variable "resource_group_name" {
  description = "Resource group where the ACR will be created"
  type        = string
}

variable "location" {
  description = "Azure region for the ACR"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the ACR"
  type        = map(string)
  default     = {}
}