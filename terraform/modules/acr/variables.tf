variable "acr_name_prefix" {
  description = "Prefix used for the globally unique Azure Container Registry name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group containing the ACR."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "sku" {
  description = "Azure Container Registry SKU."
  type        = string
  default     = "Standard"

  validation {
    condition = contains(
      ["Basic", "Standard", "Premium"],
      var.sku
    )

    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}

variable "tags" {
  description = "Common Azure resource tags."
  type        = map(string)
  default     = {}
}

