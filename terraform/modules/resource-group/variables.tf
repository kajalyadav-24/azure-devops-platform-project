variable "name" {
  description = "Name of the Azure Resource Group."
  type        = string
}

variable "location" {
  description = "Azure region where resources will be deployed."
  type        = string
}

variable "tags" {
  description = "Tags applied to the Resource Group."
  type        = map(string)
  default     = {}
}