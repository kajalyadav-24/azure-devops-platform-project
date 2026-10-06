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