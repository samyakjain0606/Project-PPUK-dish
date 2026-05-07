output "resource_groups" {
  value = {
    core      = data.azurerm_resource_group.core.name
    data      = data.azurerm_resource_group.data.name
    analytics = data.azurerm_resource_group.analytics.name
  }
}

output "log_analytics_workspace_id" {
  value = module.log_analytics.resource_id
}

output "virtual_network_id" {
  value = data.azurerm_virtual_network.vnet.id
}

output "key_vault_id" {
  value = module.key_vault.resource_id
}

output "sql_managed_instance_id" {
  value = module.sql_mi.resource_id
}

output "data_factory_ssis_id" {
  value = module.adf_ssis.resource_id
}

output "storage_accounts" {
  value = {
    adls         = module.adls.name
    blob         = module.blob.name
    function_app = module.function_app_storage.name
  }
}

output "purview_account_id" {
  value = one(azurerm_purview_account.this[*].id)
}

output "function_app_id" {
  value = azurerm_linux_function_app.this.id
}
