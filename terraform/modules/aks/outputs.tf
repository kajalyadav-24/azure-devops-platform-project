output "cluster_id" {
  description = "AKS cluster resource ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "AKS cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "node_resource_group" {
  description = "Azure-managed Resource Group containing AKS node resources."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "kubelet_identity_object_id" {
  description = "Object ID of the AKS kubelet managed identity."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL used by Azure Workload Identity."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "control_plane_identity_id" {
  description = "User Assigned Managed Identity used by the AKS control plane."
  value       = azurerm_user_assigned_identity.aks.id
}

