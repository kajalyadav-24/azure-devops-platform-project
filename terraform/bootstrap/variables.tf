variable "location" {
  description = "Azure region used for Terraform backend resources."
  type        = string
  default     = "centralindia"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project identifier used in Azure resource naming."
  type        = string
  default     = "cloudops"
}

variable "tags" {
  description = "Common tags applied to Azure resources."
  type        = map(string)

  default = {
    Project     = "Azure-DevOps-Platform"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Purpose     = "Terraform-Remote-State"
  }
}

