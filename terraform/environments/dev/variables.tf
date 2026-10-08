variable "location" {
  description = "Azure region for the development environment."
  type        = string
  default     = "centralindia"
}

variable "resource_group_name" {
  description = "Name of the development Resource Group."
  type        = string
  default     = "rg-cloudops-dev"
}

variable "tags" {
  description = "Common tags applied to Azure resources."
  type        = map(string)

  default = {
    Project     = "Azure-DevOps-Platform"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
variable "vnet_name" {
  description = "Name of the development Virtual Network."
  type        = string
  default     = "vnet-cloudops-dev"
}

variable "vnet_address_space" {
  description = "Address space for the development Virtual Network."
  type        = list(string)

  default = [
    "10.10.0.0/16"
  ]
}

variable "subnets" {
  description = "Subnet configuration for the development environment."

  type = map(object({
    address_prefixes = list(string)
  }))

  default = {
    "snet-aks-dev" = {
      address_prefixes = [
        "10.10.1.0/24"
      ]
    }

    "snet-app-dev" = {
      address_prefixes = [
        "10.10.2.0/24"
      ]
    }
  }
}
variable "acr_name_prefix" {
  description = "Prefix used for the development Azure Container Registry."
  type        = string
  default     = "acrcloudopsdev"
}

variable "acr_sku" {
  description = "Development Azure Container Registry SKU."
  type        = string
  default     = "Standard"
}
variable "aks_cluster_name" {
  description = "Name of the development AKS cluster."
  type        = string
  default     = "aks-cloudops-dev"
}

variable "aks_dns_prefix" {
  description = "DNS prefix for the development AKS cluster."
  type        = string
  default     = "cloudops-dev"
}

variable "aks_node_vm_size" {
  description = "VM size for the development AKS system nodes."
  type        = string
  default     = "Standard_D4s_v4"
}

variable "aks_node_count" {
  description = "Number of nodes in the development AKS system pool."
  type        = number
  default     = 2
}
variable "alert_email" {
  description = "Email address for Azure Monitor alert notifications."
  type        = string
}