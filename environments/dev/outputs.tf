#RG
output "resource_group_name" {
  description = "Name of the Dev Resource Group"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "ID of the Dev Resource Group"
  value       = module.resource_group.id
}

# ACR
output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = module.container_registry.name
}

output "acr_login_server" {
  description = "ACR login server"
  value       = module.container_registry.login_server
}


# AKS

output "aks_name" {
  value = module.aks.name
}

output "aks_id" {
  value = module.aks.id
}