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