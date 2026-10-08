variable "name_prefix" {
  description = "Prefix used for the globally unique Key Vault name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name."
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID."
  type        = string
}

variable "workload_identity_name" {
  description = "Name of the workload managed identity."
  type        = string
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL exposed by AKS."
  type        = string
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace containing the workload."
  type        = string
}

variable "service_account_name" {
  description = "Kubernetes ServiceAccount federated with Azure."
  type        = string
}

variable "tags" {
  description = "Common Azure tags."
  type        = map(string)
  default     = {}
}
