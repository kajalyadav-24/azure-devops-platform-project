resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_key_vault" "this" {
  name                = "${var.name_prefix}-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id

  sku_name = "standard"

  rbac_authorization_enabled = true

  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  public_network_access_enabled = true

  tags = var.tags
}

resource "azurerm_user_assigned_identity" "workload" {
  name                = var.workload_identity_name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_federated_identity_credential" "workload" {
  name = "fic-incident-app"

  user_assigned_identity_id = azurerm_user_assigned_identity.workload.id

  audience = [
    "api://AzureADTokenExchange"
  ]

  issuer  = var.oidc_issuer_url
  subject = "system:serviceaccount:${var.kubernetes_namespace}:${var.service_account_name}"
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}
