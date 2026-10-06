data "azurerm_client_config" "current" {}

resource "random_string" "storage_suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "azurerm_resource_group" "terraform_state" {
  name     = "rg-tfstate-${var.project_name}-${var.environment}"
  location = var.location

  tags = var.tags
}

resource "azurerm_storage_account" "terraform_state" {
  name = "sttf${random_string.storage_suffix.result}"

  resource_group_name = azurerm_resource_group.terraform_state.name
  location            = azurerm_resource_group.terraform_state.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_2"

  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "terraform_state" {
  name = "tfstate"

  storage_account_id = azurerm_storage_account.terraform_state.id

  container_access_type = "private"
}

resource "azurerm_role_assignment" "terraform_state_access" {
  scope = azurerm_storage_account.terraform_state.id

  role_definition_name = "Storage Blob Data Contributor"

  principal_id = data.azurerm_client_config.current.object_id
}

