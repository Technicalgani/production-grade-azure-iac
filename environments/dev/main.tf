# ---------------------------------------------------------
# Resource Group
# ---------------------------------------------------------

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


# ---------------------------------------------------------
# ACR
# ---------------------------------------------------------

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


# ---------------------------------------------------------
# AKS
# ---------------------------------------------------------
/*
module "aks" {
  source = "../../modules/aks"

  name                = "aks-${var.project_name}-${var.environment}"
  resource_group_name = module.resource_group.name
  location            = var.location

  vm_size = "Standard_B2s_v2"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Repository  = "production-grade-azure-iac"
  }
}


# ---------------------------------------------------------
# AKS → ACR permission
# ---------------------------------------------------------

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id = module.aks.kubelet_identity_object_id

  role_definition_name = "AcrPull"

  scope = module.container_registry.id
} */