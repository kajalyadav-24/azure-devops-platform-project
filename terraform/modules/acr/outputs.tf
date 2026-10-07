output "acr_id" {
  description = "Azure Container Registry resource ID."
  value       = azurerm_container_registry.this.id
}

output "acr_name" {
  description = "Azure Container Registry name."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Azure Container Registry login server."
  value       = azurerm_container_registry.this.login_server
}

