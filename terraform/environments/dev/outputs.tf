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
output "aks_cluster_id" {
  description = "Development AKS cluster resource ID."
  value       = module.aks.cluster_id
}

output "aks_cluster_name" {
  description = "Development AKS cluster name."
  value       = module.aks.cluster_name
}

output "aks_node_resource_group" {
  description = "AKS managed node Resource Group."
  value       = module.aks.node_resource_group
}

output "aks_oidc_issuer_url" {
  description = "AKS OIDC issuer URL."
  value       = module.aks.oidc_issuer_url
}

output "aks_kubelet_identity_object_id" {
  description = "AKS kubelet managed identity object ID."
  value       = module.aks.kubelet_identity_object_id
}