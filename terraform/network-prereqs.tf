resource "azurerm_network_security_group" "sql_mi" {
  name                = "nsg-${local.names.sql_mi}"
  location            = var.location
  resource_group_name = module.rg_core.name
  tags                = local.tags

  depends_on = [module.rg_core]
}

resource "azurerm_network_security_rule" "sql_mi_allow_management_inbound" {
  name                        = "allow_management_inbound"
  priority                    = 106
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["9000", "9003", "1438", "1440", "1452"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = module.rg_core.name
  network_security_group_name = azurerm_network_security_group.sql_mi.name
}

resource "azurerm_network_security_rule" "sql_mi_allow_tds_inbound" {
  name                        = "allow_tds_inbound"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = module.rg_core.name
  network_security_group_name = azurerm_network_security_group.sql_mi.name
}

resource "azurerm_network_security_rule" "sql_mi_deny_all_inbound" {
  name                        = "deny_all_inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = module.rg_core.name
  network_security_group_name = azurerm_network_security_group.sql_mi.name
}

resource "azurerm_route_table" "sql_mi" {
  name                          = "rt-${local.names.sql_mi}"
  location                      = var.location
  resource_group_name           = module.rg_core.name
  bgp_route_propagation_enabled = false
  tags                          = local.tags

  depends_on = [module.rg_core]
}
