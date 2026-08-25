output "resource_group_name" {
  description = "Name of the Dev Resource Group"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "ID of the Dev Resource Group"
  value       = module.resource_group.id
}