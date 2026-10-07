variable "vnet_name" {
  description = "Name of the Azure Virtual Network."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group containing the Virtual Network."
  type        = string
}

variable "address_space" {
  description = "Address space assigned to the Virtual Network."
  type        = list(string)
}

variable "subnets" {
  description = "Subnet configuration."

  type = map(object({
    address_prefixes = list(string)
  }))
}

variable "tags" {
  description = "Common tags applied to resources."
  type        = map(string)
  default     = {}
}

