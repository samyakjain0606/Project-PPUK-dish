output "resource_groups" {
  value = {
    core      = module.rg_core.name
    data      = module.rg_data.name
    analytics = module.rg_analytics.name
  }
}

output "log_analytics_workspace_id" {
  value = module.log_analytics.resource_id
}

output "virtual_network_id" {
  value = module.vnet.resource_id
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
    adls = module.adls.name
    blob = module.blob.name
  }
}
