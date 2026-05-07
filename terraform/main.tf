data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "core" {
  name = local.names.rg_core
}

data "azurerm_resource_group" "data" {
  name = local.names.rg_data
}

data "azurerm_resource_group" "analytics" {
  name = local.names.rg_analytics
}

data "azurerm_virtual_network" "vnet" {
  name                = local.names.vnet
  resource_group_name = data.azurerm_resource_group.core.name
}

data "azurerm_subnet" "sql_mi" {
  name                 = local.subnet_names.sql_mi
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.core.name
}

data "azurerm_subnet" "private_endpoints" {
  name                 = local.subnet_names.private_endpoints
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.core.name
}

data "azurerm_subnet" "data_factory" {
  name                 = local.subnet_names.data_factory
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.core.name
}

data "azurerm_subnet" "analytics" {
  name                 = local.subnet_names.analytics
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.core.name
}

data "azurerm_subnet" "function_app" {
  count                = var.enable_function_app_vnet_integration ? 1 : 0
  name                 = local.subnet_names.function_app
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.core.name
}

module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  location                                  = var.location
  name                                      = local.names.log_analytics
  resource_group_name                       = data.azurerm_resource_group.core.name
  enable_telemetry                          = var.enable_telemetry
  log_analytics_workspace_retention_in_days = 90
  log_analytics_workspace_sku               = "PerGB2018"
  tags                                      = local.tags
}

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  location                      = var.location
  name                          = local.names.key_vault
  resource_group_name           = data.azurerm_resource_group.core.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  enable_telemetry              = var.enable_telemetry
  public_network_access_enabled = false
  purge_protection_enabled      = true
  sku_name                      = "standard"
  soft_delete_retention_days    = 90
  legacy_access_policies_enabled = false
  tags                          = local.tags

  diagnostic_settings = {
    logs = {
      workspace_resource_id = module.log_analytics.resource_id
    }
  }

  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  role_assignments = {
    deployer_admin = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }

  depends_on = [module.log_analytics]
}

module "adls" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.8"

  location                          = var.location
  name                              = local.names.adls_account
  resource_group_name               = data.azurerm_resource_group.data.name
  account_kind                      = "StorageV2"
  account_replication_type          = local.is_prod ? "ZRS" : "LRS"
  account_tier                      = "Standard"
  shared_access_key_enabled         = false
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  public_network_access_enabled     = false
  is_hns_enabled                    = true
  infrastructure_encryption_enabled = true
  enable_telemetry                  = var.enable_telemetry
  tags                              = local.tags

  managed_identities = {
    system_assigned = true
  }

  diagnostic_settings_blob = {
    logs = {
      workspace_resource_id = module.log_analytics.resource_id
    }
  }

  network_rules = {
    bypass                     = ["AzureServices"]
    default_action             = "Deny"
    virtual_network_subnet_ids = toset([data.azurerm_subnet.data_factory.id, data.azurerm_subnet.analytics.id])
  }

  depends_on = [module.log_analytics]
}

module "blob" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.8"

  location                          = var.location
  name                              = local.names.blob_account
  resource_group_name               = data.azurerm_resource_group.data.name
  account_kind                      = "StorageV2"
  account_replication_type          = local.is_prod ? "ZRS" : "LRS"
  account_tier                      = "Standard"
  shared_access_key_enabled         = false
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  public_network_access_enabled     = false
  infrastructure_encryption_enabled = true
  enable_telemetry                  = var.enable_telemetry
  tags                              = local.tags

  managed_identities = {
    system_assigned = true
  }

  containers = {
    aae_project_data = {
      name = "aae-project-data"
    }
  }

  diagnostic_settings_blob = {
    logs = {
      workspace_resource_id = module.log_analytics.resource_id
    }
  }

  network_rules = {
    bypass                     = ["AzureServices"]
    default_action             = "Deny"
    virtual_network_subnet_ids = toset([data.azurerm_subnet.data_factory.id, data.azurerm_subnet.analytics.id])
  }

  depends_on = [module.log_analytics]
}

module "sql_mi" {
  source  = "Azure/avm-res-sql-managedinstance/azurerm"
  version = "0.2.1"

  administrator_login          = var.sql_mi_administrator_login
  administrator_login_password = var.sql_mi_administrator_password
  license_type                 = "BasePrice"
  location                     = var.location
  name                         = local.names.sql_mi
  resource_group_name          = data.azurerm_resource_group.data.name
  sku_name                     = "GP_Gen5"
  storage_size_in_gb           = var.sql_mi_storage_size_in_gb
  subnet_id                    = data.azurerm_subnet.sql_mi.id
  vcores                       = var.sql_mi_vcores
  minimum_tls_version          = "1.2"
  public_data_endpoint_enabled = false
  zone_redundant_enabled       = local.is_prod
  service_principal_enabled    = true
  enable_telemetry             = var.enable_telemetry
  tags                         = local.tags

  managed_identities = {
    system_assigned = true
  }

  diagnostic_settings = {
    logs = {
      workspace_resource_id = module.log_analytics.resource_id
    }
  }

  depends_on = [module.log_analytics]
}

module "adf_ssis" {
  source  = "Azure/avm-res-datafactory-factory/azurerm"
  version = "0.1.0"

  location                        = var.location
  name                            = local.names.adf_ssis
  resource_group_name             = data.azurerm_resource_group.data.name
  enable_telemetry                = var.enable_telemetry
  managed_virtual_network_enabled = true
  public_network_enabled          = false
  purview_id                      = one(azurerm_purview_account.this[*].id)
  tags                            = local.tags

  managed_identities = {
    system_assigned = true
  }

  diagnostic_settings = {
    logs = {
      workspace_resource_id = module.log_analytics.resource_id
    }
  }

  linked_service_key_vault = {
    platform = {
      name         = "ls-keyvault-platform"
      key_vault_id = module.key_vault.resource_id
    }
  }

  depends_on = [module.key_vault, module.log_analytics, azurerm_purview_account.this]
}

module "adf_general" {
  count   = var.enable_native_adf ? 1 : 0
  source  = "Azure/avm-res-datafactory-factory/azurerm"
  version = "0.1.0"

  location                        = var.location
  name                            = local.names.adf_general
  resource_group_name             = data.azurerm_resource_group.data.name
  enable_telemetry                = var.enable_telemetry
  managed_virtual_network_enabled = true
  public_network_enabled          = false
  purview_id                      = one(azurerm_purview_account.this[*].id)
  tags                            = local.tags

  managed_identities = {
    system_assigned = true
  }

  diagnostic_settings = {
    logs = {
      workspace_resource_id = module.log_analytics.resource_id
    }
  }

  linked_service_key_vault = {
    platform = {
      name         = "ls-keyvault-platform"
      key_vault_id = module.key_vault.resource_id
    }
  }

  linked_service_data_lake_storage_gen2 = {
    platform = {
      name                 = "ls-adls-platform"
      url                  = "https://${module.adls.name}.dfs.core.windows.net"
      use_managed_identity = true
    }
  }

  depends_on = [module.key_vault, module.adls, module.log_analytics, azurerm_purview_account.this]
}

module "databricks_lab" {
  count   = var.enable_analytics ? 1 : 0
  source  = "Azure/avm-res-databricks-workspace/azurerm"
  version = "0.4.0"

  location                      = var.location
  name                          = local.names.databricks
  resource_group_name           = data.azurerm_resource_group.analytics.name
  sku                           = "premium"
  public_network_access_enabled = false
  enable_telemetry              = var.enable_telemetry
  tags                          = local.tags

  enhanced_security_compliance = {
    automatic_cluster_update_enabled      = false
    compliance_security_profile_enabled   = false
    compliance_security_profile_standards = []
    enhanced_security_monitoring_enabled  = false
  }
}

module "azureml" {
  count   = var.enable_analytics ? 1 : 0
  source  = "Azure/avm-res-machinelearningservices-workspace/azurerm"
  version = "0.9.0"

  location                      = var.location
  name                          = local.names.aml_workspace
  resource_group_name           = data.azurerm_resource_group.analytics.name
  enable_telemetry              = var.enable_telemetry
  public_network_access_enabled = false
  tags                          = local.tags

  key_vault = {
    resource_id = module.key_vault.resource_id
  }
  storage_account = {
    resource_id = module.blob.resource_id
  }
  managed_identities = {
    system_assigned = true
  }

  depends_on = [module.key_vault, module.blob]
}
