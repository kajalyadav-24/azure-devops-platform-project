variable "nsg_name" {
  description = "Name of the Network Security Group."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group containing the NSG."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to associate with the NSG."
  type        = string
}

variable "security_rules" {
  description = "Security rules for the NSG."

  type = map(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))

  default = {}
}

variable "tags" {
  description = "Common Azure tags."
  type        = map(string)
  default     = {}
}

