# BUDGET
variable "budget_alert_email" {
  description = "Email address for Azure budget alerts"
  type        = string
}

# RG
variable "location" {
  description = "Azure region for the dev environment"
  type        = string
  default     = "centralindia"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "azure-iac"
}

# ACR
variable "name" {
  description = "Project name"
  type        = string
  default     = "azure-iac"
}
