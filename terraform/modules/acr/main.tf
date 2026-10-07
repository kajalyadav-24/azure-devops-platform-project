resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_container_registry" "this" {
  name = "${var.acr_name_prefix}${random_string.suffix.result}"

  resource_group_name = var.resource_group_name
  location            = var.location

  sku           = var.sku
  admin_enabled = false

  public_network_access_enabled = true

  tags = var.tags
}

