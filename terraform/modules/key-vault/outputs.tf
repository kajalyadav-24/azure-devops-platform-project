output "key_vault_id" {
  value = azurerm_key_vault.this.id
}

output "key_vault_name" {
  value = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "workload_identity_id" {
  value = azurerm_user_assigned_identity.workload.id
}

output "workload_identity_client_id" {
  value = azurerm_user_assigned_identity.workload.client_id
}

output "workload_identity_principal_id" {
  value = azurerm_user_assigned_identity.workload.principal_id
}
