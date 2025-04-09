# Outputs
output "zenml_server_url" {
  value = azurerm_container_app.zenml_app.latest_revision_fqdn
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "mysql_server_fqdn" {
  value = azurerm_mysql_flexible_server.mysql.fqdn
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}
