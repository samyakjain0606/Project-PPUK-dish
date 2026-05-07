resource "azurerm_storage_management_policy" "aae_blob" {
  storage_account_id = module.blob.resource_id

  rule {
    name    = "aae-lifecycle"
    enabled = true

    filters {
      prefix_match = ["aae-project-data/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 180
        tier_to_archive_after_days_since_modification_greater_than = 730
      }
    }
  }

  depends_on = [module.blob]
}
