locals {
  is_prod = var.environment == "prod"

  tags = {
    application = "ppuk-data-platform"
    asset       = var.asset
    environment = var.environment
    location    = var.location
    owner       = var.owner
    costCentre  = var.cost_centre
    managedBy   = "terraform"
  }

  names = {
    rg_core      = "ppg-rg-${var.asset}-${var.region_code}-${var.environment}-core-001"
    rg_data      = "ppg-rg-${var.asset}-${var.region_code}-${var.environment}-data-001"
    rg_analytics = "ppg-rg-${var.asset}-${var.region_code}-${var.environment}-analytics-001"

    vnet          = "ppg-vnet-${var.asset}-${var.region_code}-${var.environment}-001"
    log_analytics = "ppg-law-${var.asset}-${var.region_code}-${var.environment}-001"
    key_vault     = "ppg-akv-${var.asset}-${var.region_code}-${var.environment}-001"

    sql_mi      = "ppg-ass-${var.asset}-sqlmi-${var.region_code}-${var.environment}-001"
    adf_ssis    = "ppg-adf-${var.asset}-ssis-${var.region_code}-${var.environment}-001"
    adf_general = "ppg-adf-${var.asset}-gp-${var.region_code}-${var.environment}-001"

    aml_workspace = "ppg-aml-${var.asset}-aae-${var.region_code}-${var.environment}-001"
    databricks    = "ppg-adb-${var.asset}-lab-${var.region_code}-${var.environment}-001"

    adls_account = "ppgadls${var.asset}dp${var.region_code}${var.environment}001"
    blob_account = "ppgabs${var.asset}aae${var.region_code}${var.environment}001"

    purview              = "ppg-apv-${var.asset}-${var.region_code}-001"
    function_app         = "ppg-afa-${var.asset}-plat-${var.region_code}-${var.environment}-001"
    function_app_plan    = "ppg-asp-${var.asset}-plat-${var.region_code}-${var.environment}-001"
    function_app_storage = "ppgst${var.asset}fa${var.region_code}${var.environment}001"
  }

  subnet_names = {
    sql_mi            = "snet-sqlmi"
    private_endpoints = "snet-private-endpoints"
    data_factory      = "snet-data-factory"
    analytics         = "snet-analytics"
    function_app      = "snet-function-app"
  }
}
