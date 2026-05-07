resource "azurerm_storage_data_lake_gen2_filesystem" "landing" {
  name               = "landing"
  storage_account_id = module.adls.resource_id

  depends_on = [module.adls]
}

resource "azurerm_storage_data_lake_gen2_filesystem" "bronze" {
  name               = "bronze"
  storage_account_id = module.adls.resource_id

  depends_on = [module.adls]
}

resource "azurerm_storage_data_lake_gen2_filesystem" "curated" {
  name               = "curated"
  storage_account_id = module.adls.resource_id

  depends_on = [module.adls]
}
