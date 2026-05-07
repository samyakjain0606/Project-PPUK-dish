resource "azurerm_purview_account" "this" {
  count                       = var.manage_purview ? 1 : 0
  name                        = local.names.purview
  resource_group_name         = data.azurerm_resource_group.data.name
  location                    = var.location
  public_network_enabled      = false
  managed_resource_group_name = "${local.names.purview}-managed"
  tags                        = local.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_monitor_diagnostic_setting" "purview" {
  count                      = var.manage_purview ? 1 : 0
  name                       = "diag-${local.names.purview}"
  target_resource_id         = azurerm_purview_account.this[0].id
  log_analytics_workspace_id = module.log_analytics.resource_id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  depends_on = [module.log_analytics]
}
