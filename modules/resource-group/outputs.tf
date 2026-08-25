output "name" {
  description = "Resource Group name"
  value       = azurerm_resource_group.this.name
}

output "id" {
  description = "Resource Group ID"
  value       = azurerm_resource_group.this.id

}