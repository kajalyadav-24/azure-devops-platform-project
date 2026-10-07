variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group containing the AKS cluster."
  type        = string
}

variable "aks_subnet_id" {
  description = "Subnet ID where AKS nodes will be deployed."
  type        = string
}

variable "acr_id" {
  description = "Azure Container Registry resource ID."
  type        = string
}

variable "node_vm_size" {
  description = "VM size used by the AKS system node pool."
  type        = string
  default     = "Standard_D4s_v4"
}

variable "node_count" {
  description = "Number of nodes in the AKS system node pool."
  type        = number
  default     = 2

  validation {
    condition     = var.node_count >= 2
    error_message = "The AKS system node pool must contain at least two nodes."
  }
}

variable "tags" {
  description = "Common Azure tags."
  type        = map(string)
  default     = {}
}

