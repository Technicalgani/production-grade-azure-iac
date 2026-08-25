# BUDGET
data "azurerm_subscription" "current" {}

module "budget" {
  source = "../../modules/budget"

  budget_name     = "budget-${var.project_name}-dev"
  subscription_id = data.azurerm_subscription.current.id

  amount     = 1000
  start_date = "2026-08-01T00:00:00Z"
  end_date   = "2027-08-01T00:00:00Z"

  contact_emails = [
    var.budget_alert_email
  ]
}

# RG
module "resource_group" {
  source = "../../modules/resource-group"

  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Repository  = "production-grade-azure-iac"
  }
}

# ACR
module "container_registry" {
  source = "../../modules/container-registry"

  name                = "acr${replace(var.project_name, "-", "")}${var.environment}01"
  resource_group_name = module.resource_group.name
  location            = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Repository  = "production-grade-azure-iac"
  }



}