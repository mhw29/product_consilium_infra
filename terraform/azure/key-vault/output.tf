output "key_vault_id" {
  value = azurerm_key_vault.current.id
}
output "key_vault_uri" {
  value = azurerm_key_vault.current.vault_uri
}