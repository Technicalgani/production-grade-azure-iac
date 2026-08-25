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