output "resource_group_name" {
  description = "Development Resource Group name."
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "Development Resource Group ID."
  value       = module.resource_group.id
}
output "vnet_id" {
  description = "Development Virtual Network ID."
  value       = module.network.vnet_id
}

output "vnet_name" {
  description = "Development Virtual Network name."
  value       = module.network.vnet_name
}

output "subnet_ids" {
  description = "Development subnet IDs."
  value       = module.network.subnet_ids
}
output "aks_nsg_id" {
  description = "AKS subnet NSG ID."
  value       = module.aks_nsg.nsg_id
}

output "app_nsg_id" {
  description = "Application subnet NSG ID."
  value       = module.app_nsg.nsg_id
}
output "acr_id" {
  description = "Development Azure Container Registry resource ID."
  value       = module.acr.acr_id
}

output "acr_name" {
  description = "Development Azure Container Registry name."
  value       = module.acr.acr_name
}

output "acr_login_server" {
  description = "Development Azure Container Registry login server."
  value       = module.acr.login_server
}