# PPUK Landing Zone Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build reusable infrastructure-as-code for the PPUK Tier 1 Data Platform landing zone setup in Azure.

**Architecture:** This implementation creates Terraform code that provisions the Azure landing zone resources required by the PDF: resource groups, naming/tagging, secure networking, Key Vault, SQL Managed Instance, Data Factory with SSIS Integration Runtime support, storage, monitoring, and optional analytics services. It deliberately excludes workload migration, SSIS package deployment, database migration, schema conversion, and data movement.

**Tech Stack:** Terraform, AzureRM provider, AzureAD provider, Azure CLI, GitHub/Azure DevOps-compatible validation scripts.

---

## Source Requirements From PDF

The plan is based on `Calandra Tier 1 Application - PPUK Data Platform Tech Requirements.pdf`.

Landing zone setup must cover:

- Region: UK South (`uks`)
- Asset shorthand: `ppuk` in service examples, while the naming convention section also mentions `puk`; use `ppuk` unless PPG confirms `puk` is mandatory.
- Environments: `dev`, `test`, `uat`, `preprod`, `prod`
- Service naming pattern: `ppg-<service>-<asset>-<identifier>-<region>-<environment>-<count>`
- Storage naming pattern without hyphens: `ppgadlsppukdpuks<environment>001`, `ppgabsppukaaeuks<environment>001`
- Required baseline services:
  - Azure Key Vault
  - Azure SQL Managed Instance
  - Azure Data Factory with managed identity
  - Azure Data Factory SSIS Integration Runtime support
  - Azure Storage Accounts for ADLS Gen2 and Blob
  - Azure DevOps pipeline definitions
  - Monitoring, diagnostic settings, and cost tags
- Optional / feature-gated services:
  - Azure Machine Learning
  - Azure Databricks LAB
  - General-purpose ADF for native pipelines
  - Azure Function App scaffold
  - Microsoft Purview registration support
- Security requirements:
  - Private networking by default
  - Managed identity preferred
  - RBAC access management
  - Key Vault for secrets
  - AES-256 encryption at rest and TLS 1.2+ in transit
  - Diagnostic settings to Log Analytics / Sentinel-ready sink
  - Public access disabled where supported

Out of scope:

- Migrating existing SQL Server databases to SQL MI
- Deploying SSIS packages into SSISDB
- Refactoring SSIS into native ADF pipelines
- Creating business data models, stored procedures, reports, or Power BI assets
- Moving production data
- Configuring Radar, Polaris, AAE workloads beyond landing zone connectivity primitives

## Proposed File Structure

Create these files:

- `README.md`: project purpose, scope, prerequisites, deployment commands.
- `.gitignore`: Terraform, local state, and plan exclusions.
- `terraform/versions.tf`: Terraform and provider version constraints.
- `terraform/providers.tf`: AzureRM and AzureAD provider setup.
- `terraform/variables.tf`: root input variables.
- `terraform/locals.tf`: common naming, environment, and tag locals.
- `terraform/main.tf`: root module wiring.
- `terraform/outputs.tf`: key resource IDs and endpoint outputs.
- `terraform/envs/dev.tfvars`: dev settings.
- `terraform/envs/test.tfvars`: test settings.
- `terraform/envs/uat.tfvars`: uat settings.
- `terraform/envs/preprod.tfvars`: preprod settings.
- `terraform/envs/prod.tfvars`: prod settings.
- `terraform/modules/naming/main.tf`: deterministic PPUK naming rules.
- `terraform/modules/naming/variables.tf`: naming module inputs.
- `terraform/modules/naming/outputs.tf`: generated names.
- `terraform/modules/foundation/main.tf`: resource groups, Log Analytics, diagnostics sink.
- `terraform/modules/foundation/variables.tf`: foundation inputs.
- `terraform/modules/foundation/outputs.tf`: foundation outputs.
- `terraform/modules/network/main.tf`: VNet, required delegated subnets, private DNS zones.
- `terraform/modules/network/variables.tf`: network inputs.
- `terraform/modules/network/outputs.tf`: subnet and DNS outputs.
- `terraform/modules/key_vault/main.tf`: Key Vault with RBAC, purge protection, private endpoint.
- `terraform/modules/key_vault/variables.tf`: Key Vault inputs.
- `terraform/modules/key_vault/outputs.tf`: vault outputs.
- `terraform/modules/sql_mi/main.tf`: SQL Managed Instance, diagnostics, auditing placeholders.
- `terraform/modules/sql_mi/variables.tf`: SQL MI inputs.
- `terraform/modules/sql_mi/outputs.tf`: SQL MI outputs.
- `terraform/modules/data_factory/main.tf`: ADF, managed identity, diagnostics, optional SSIS IR.
- `terraform/modules/data_factory/variables.tf`: ADF inputs.
- `terraform/modules/data_factory/outputs.tf`: ADF outputs.
- `terraform/modules/storage/main.tf`: ADLS Gen2 and Blob storage accounts.
- `terraform/modules/storage/variables.tf`: storage inputs.
- `terraform/modules/storage/outputs.tf`: storage outputs.
- `terraform/modules/analytics/main.tf`: optional Azure ML and Databricks workspace scaffolds.
- `terraform/modules/analytics/variables.tf`: analytics inputs.
- `terraform/modules/analytics/outputs.tf`: analytics outputs.
- `terraform/modules/function_app/main.tf`: optional Function App scaffold.
- `terraform/modules/function_app/variables.tf`: Function App inputs.
- `terraform/modules/function_app/outputs.tf`: Function App outputs.
- `pipelines/azure-pipelines-validate.yml`: CI validation for formatting and Terraform validation.
- `scripts/validate.sh`: local validation wrapper.

## Task 1: Scaffold Terraform Project

**Files:**
- Create: `README.md`
- Create: `.gitignore`
- Create: `terraform/versions.tf`
- Create: `terraform/providers.tf`
- Create: `terraform/variables.tf`
- Create: `terraform/main.tf`
- Create: `terraform/outputs.tf`
- Create: `scripts/validate.sh`

- [ ] **Step 1: Create repository README**

Create `README.md`:

```markdown
# PPUK Data Platform Landing Zone

Terraform infrastructure-as-code for the PPUK Tier 1 Data Platform landing zone.

## Scope

This repository provisions Azure landing zone resources only. It does not migrate SQL databases, deploy SSIS packages, refactor pipelines, move data, or configure business reports.

## Environments

- dev
- test
- uat
- preprod
- prod

## Validate

```bash
./scripts/validate.sh
```

## Plan

```bash
cd terraform
terraform init
terraform plan -var-file=envs/dev.tfvars
```
```

- [ ] **Step 2: Create `.gitignore`**

```gitignore
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.*
*.tfplan
crash.log
crash.*.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
.DS_Store
```

- [ ] **Step 3: Create Terraform version constraints**

Create `terraform/versions.tf`:

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
```

- [ ] **Step 4: Create providers**

Create `terraform/providers.tf`:

```hcl
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "azuread" {}
```

- [ ] **Step 5: Create root variables**

Create `terraform/variables.tf`:

```hcl
variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "test", "uat", "preprod", "prod"], var.environment)
    error_message = "environment must be one of dev, test, uat, preprod, prod."
  }
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "uksouth"
}

variable "asset" {
  description = "Asset shorthand used in resource names."
  type        = string
  default     = "ppuk"
}

variable "region_code" {
  description = "Short region code used in resource names."
  type        = string
  default     = "uks"
}

variable "owner" {
  description = "Business or platform owner tag."
  type        = string
}

variable "cost_centre" {
  description = "Cost centre tag."
  type        = string
}

variable "enable_native_adf" {
  description = "Deploy general-purpose ADF for future native pipelines."
  type        = bool
  default     = false
}

variable "enable_analytics" {
  description = "Deploy optional Azure ML and Databricks LAB scaffolding."
  type        = bool
  default     = false
}

variable "enable_function_app" {
  description = "Deploy optional Azure Function App scaffold."
  type        = bool
  default     = false
}
```

- [ ] **Step 6: Create validation script**

Create `scripts/validate.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../terraform"
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

Run:

```bash
chmod +x scripts/validate.sh
```

Expected: script is executable.

## Task 2: Implement Naming, Tags, and Environment Inputs

**Files:**
- Create: `terraform/locals.tf`
- Create: `terraform/modules/naming/main.tf`
- Create: `terraform/modules/naming/variables.tf`
- Create: `terraform/modules/naming/outputs.tf`
- Create: `terraform/envs/dev.tfvars`
- Create: `terraform/envs/test.tfvars`
- Create: `terraform/envs/uat.tfvars`
- Create: `terraform/envs/preprod.tfvars`
- Create: `terraform/envs/prod.tfvars`

- [ ] **Step 1: Create common locals**

Create `terraform/locals.tf`:

```hcl
locals {
  common_tags = {
    application = "ppuk-data-platform"
    asset       = var.asset
    environment = var.environment
    location    = var.location
    owner       = var.owner
    costCentre  = var.cost_centre
    managedBy   = "terraform"
  }

  is_prod = var.environment == "prod"
}
```

- [ ] **Step 2: Create naming module inputs**

Create `terraform/modules/naming/variables.tf`:

```hcl
variable "asset" {
  type = string
}

variable "region_code" {
  type = string
}

variable "environment" {
  type = string
}
```

- [ ] **Step 3: Create naming module logic**

Create `terraform/modules/naming/main.tf`:

```hcl
locals {
  prefix = "ppg"
  suffix = "${var.asset}-${var.region_code}-${var.environment}"

  resource_group_core      = "${local.prefix}-rg-${local.suffix}-core-001"
  resource_group_data      = "${local.prefix}-rg-${local.suffix}-data-001"
  resource_group_analytics = "${local.prefix}-rg-${local.suffix}-analytics-001"

  vnet                 = "${local.prefix}-vnet-${local.suffix}-001"
  log_analytics        = "${local.prefix}-law-${local.suffix}-001"
  key_vault            = "${local.prefix}-akv-${var.asset}-${var.region_code}-${var.environment}-001"
  sql_managed_instance = "${local.prefix}-ass-${var.asset}-sqlmi-${var.region_code}-${var.environment}-001"
  adf_ssis             = "${local.prefix}-adf-${var.asset}-ssis-${var.region_code}-${var.environment}-001"
  adf_general          = "${local.prefix}-adf-${var.asset}-gp-${var.region_code}-${var.environment}-001"
  function_app         = "${local.prefix}-afa-${var.asset}-lz-${var.region_code}-${var.environment}-001"
  aml_workspace        = "${local.prefix}-aml-${var.asset}-aae-${var.region_code}-${var.environment}-001"
  databricks           = "${local.prefix}-adb-${var.asset}-lab-${var.region_code}-${var.environment}-001"

  adls_account = "ppgadls${var.asset}dp${var.region_code}${var.environment}001"
  blob_account = "ppgabs${var.asset}aae${var.region_code}${var.environment}001"
}
```

- [ ] **Step 4: Create naming outputs**

Create `terraform/modules/naming/outputs.tf`:

```hcl
output "resource_group_core" { value = local.resource_group_core }
output "resource_group_data" { value = local.resource_group_data }
output "resource_group_analytics" { value = local.resource_group_analytics }
output "vnet" { value = local.vnet }
output "log_analytics" { value = local.log_analytics }
output "key_vault" { value = local.key_vault }
output "sql_managed_instance" { value = local.sql_managed_instance }
output "adf_ssis" { value = local.adf_ssis }
output "adf_general" { value = local.adf_general }
output "function_app" { value = local.function_app }
output "aml_workspace" { value = local.aml_workspace }
output "databricks" { value = local.databricks }
output "adls_account" { value = local.adls_account }
output "blob_account" { value = local.blob_account }
```

- [ ] **Step 5: Create tfvars for each environment**

Create `terraform/envs/dev.tfvars`:

```hcl
environment         = "dev"
owner               = "ppuk-data-platform"
cost_centre         = "confirm-with-ppg"
enable_native_adf   = true
enable_analytics    = true
enable_function_app = true
```

Create `terraform/envs/test.tfvars`:

```hcl
environment         = "test"
owner               = "ppuk-data-platform"
cost_centre         = "confirm-with-ppg"
enable_native_adf   = true
enable_analytics    = false
enable_function_app = false
```

Create `terraform/envs/uat.tfvars`:

```hcl
environment         = "uat"
owner               = "ppuk-data-platform"
cost_centre         = "confirm-with-ppg"
enable_native_adf   = true
enable_analytics    = false
enable_function_app = false
```

Create `terraform/envs/preprod.tfvars`:

```hcl
environment         = "preprod"
owner               = "ppuk-data-platform"
cost_centre         = "confirm-with-ppg"
enable_native_adf   = true
enable_analytics    = false
enable_function_app = false
```

Create `terraform/envs/prod.tfvars`:

```hcl
environment         = "prod"
owner               = "ppuk-data-platform"
cost_centre         = "confirm-with-ppg"
enable_native_adf   = true
enable_analytics    = false
enable_function_app = false
```

## Task 3: Build Foundation and Network Modules

**Files:**
- Create: `terraform/modules/foundation/main.tf`
- Create: `terraform/modules/foundation/variables.tf`
- Create: `terraform/modules/foundation/outputs.tf`
- Create: `terraform/modules/network/main.tf`
- Create: `terraform/modules/network/variables.tf`
- Create: `terraform/modules/network/outputs.tf`
- Modify: `terraform/main.tf`

- [ ] **Step 1: Create foundation variables**

Create `terraform/modules/foundation/variables.tf`:

```hcl
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "names" {
  type = object({
    resource_group_core      = string
    resource_group_data      = string
    resource_group_analytics = string
    log_analytics            = string
  })
}
```

- [ ] **Step 2: Create foundation resources**

Create `terraform/modules/foundation/main.tf`:

```hcl
resource "azurerm_resource_group" "core" {
  name     = var.names.resource_group_core
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "data" {
  name     = var.names.resource_group_data
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "analytics" {
  name     = var.names.resource_group_analytics
  location = var.location
  tags     = var.tags
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = var.names.log_analytics
  location            = azurerm_resource_group.core.location
  resource_group_name = azurerm_resource_group.core.name
  sku                 = "PerGB2018"
  retention_in_days   = 90
  tags                = var.tags
}
```

- [ ] **Step 3: Create foundation outputs**

Create `terraform/modules/foundation/outputs.tf`:

```hcl
output "core_resource_group_name" { value = azurerm_resource_group.core.name }
output "data_resource_group_name" { value = azurerm_resource_group.data.name }
output "analytics_resource_group_name" { value = azurerm_resource_group.analytics.name }
output "log_analytics_workspace_id" { value = azurerm_log_analytics_workspace.main.id }
```

- [ ] **Step 4: Create network module**

Create `terraform/modules/network/variables.tf`:

```hcl
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "vnet_name" { type = string }
variable "tags" { type = map(string) }

variable "address_space" {
  type    = list(string)
  default = ["10.80.0.0/16"]
}
```

Create `terraform/modules/network/main.tf`:

```hcl
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "sql_mi" {
  name                 = "snet-sqlmi"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.80.1.0/24"]

  delegation {
    name = "sqlmi"
    service_delegation {
      name = "Microsoft.Sql/managedInstances"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.80.2.0/24"]
}

resource "azurerm_subnet" "data_factory" {
  name                 = "snet-data-factory"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.80.3.0/24"]
}

resource "azurerm_subnet" "analytics" {
  name                 = "snet-analytics"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.80.4.0/24"]
}
```

Create `terraform/modules/network/outputs.tf`:

```hcl
output "vnet_id" { value = azurerm_virtual_network.main.id }
output "sql_mi_subnet_id" { value = azurerm_subnet.sql_mi.id }
output "private_endpoint_subnet_id" { value = azurerm_subnet.private_endpoints.id }
output "data_factory_subnet_id" { value = azurerm_subnet.data_factory.id }
output "analytics_subnet_id" { value = azurerm_subnet.analytics.id }
```

- [ ] **Step 5: Wire root modules**

Create `terraform/main.tf`:

```hcl
module "naming" {
  source      = "./modules/naming"
  asset       = var.asset
  region_code = var.region_code
  environment = var.environment
}

module "foundation" {
  source   = "./modules/foundation"
  location = var.location
  tags     = local.common_tags
  names = {
    resource_group_core      = module.naming.resource_group_core
    resource_group_data      = module.naming.resource_group_data
    resource_group_analytics = module.naming.resource_group_analytics
    log_analytics            = module.naming.log_analytics
  }
}

module "network" {
  source              = "./modules/network"
  location            = var.location
  resource_group_name = module.foundation.core_resource_group_name
  vnet_name           = module.naming.vnet
  tags                = local.common_tags
}
```

## Task 4: Implement Key Vault, Storage, SQL MI, and Data Factory Modules

**Files:**
- Create: `terraform/modules/key_vault/main.tf`
- Create: `terraform/modules/key_vault/variables.tf`
- Create: `terraform/modules/key_vault/outputs.tf`
- Create: `terraform/modules/storage/main.tf`
- Create: `terraform/modules/storage/variables.tf`
- Create: `terraform/modules/storage/outputs.tf`
- Create: `terraform/modules/sql_mi/main.tf`
- Create: `terraform/modules/sql_mi/variables.tf`
- Create: `terraform/modules/sql_mi/outputs.tf`
- Create: `terraform/modules/data_factory/main.tf`
- Create: `terraform/modules/data_factory/variables.tf`
- Create: `terraform/modules/data_factory/outputs.tf`
- Modify: `terraform/main.tf`

- [ ] **Step 1: Implement Key Vault**

Create `terraform/modules/key_vault/variables.tf`:

```hcl
variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tenant_id" { type = string }
variable "log_analytics_workspace_id" { type = string }
variable "tags" { type = map(string) }
```

Create `terraform/modules/key_vault/main.tf`:

```hcl
resource "azurerm_key_vault" "main" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  enable_rbac_authorization     = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90
  public_network_access_enabled = false
  tags                          = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
```

Create `terraform/modules/key_vault/outputs.tf`:

```hcl
output "id" { value = azurerm_key_vault.main.id }
output "name" { value = azurerm_key_vault.main.name }
output "vault_uri" { value = azurerm_key_vault.main.vault_uri }
```

- [ ] **Step 2: Implement storage**

Create `terraform/modules/storage/variables.tf`:

```hcl
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "adls_name" { type = string }
variable "blob_name" { type = string }
variable "is_prod" { type = bool }
variable "log_analytics_workspace_id" { type = string }
variable "tags" { type = map(string) }
```

Create `terraform/modules/storage/main.tf`:

```hcl
resource "azurerm_storage_account" "adls" {
  name                            = var.adls_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = var.is_prod ? "ZRS" : "LRS"
  account_kind                    = "StorageV2"
  is_hns_enabled                  = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  public_network_access_enabled   = false
  tags                            = var.tags
}

resource "azurerm_storage_account" "blob" {
  name                            = var.blob_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = var.is_prod ? "ZRS" : "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  public_network_access_enabled   = false
  tags                            = var.tags
}

resource "azurerm_storage_container" "aae" {
  name                  = "aae-project-data"
  storage_account_name  = azurerm_storage_account.blob.name
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "blob" {
  storage_account_id = azurerm_storage_account.blob.id

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
}
```

Create `terraform/modules/storage/outputs.tf`:

```hcl
output "adls_id" { value = azurerm_storage_account.adls.id }
output "blob_id" { value = azurerm_storage_account.blob.id }
output "adls_name" { value = azurerm_storage_account.adls.name }
output "blob_name" { value = azurerm_storage_account.blob.name }
```

- [ ] **Step 3: Implement SQL MI scaffold**

Create `terraform/modules/sql_mi/variables.tf`:

```hcl
variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "subnet_id" { type = string }
variable "administrator_login" { type = string }
variable "administrator_password" {
  type      = string
  sensitive = true
}
variable "log_analytics_workspace_id" { type = string }
variable "tags" { type = map(string) }
```

Create `terraform/modules/sql_mi/main.tf`:

```hcl
resource "azurerm_mssql_managed_instance" "main" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  subnet_id                    = var.subnet_id
  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_password
  license_type                 = "BasePrice"
  sku_name                     = "GP_Gen5"
  vcores                       = 16
  storage_size_in_gb           = 1024
  minimum_tls_version          = "1.2"
  public_data_endpoint_enabled = false
  tags                         = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_mssql_managed_instance.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SQLSecurityAuditEvents"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
```

Create `terraform/modules/sql_mi/outputs.tf`:

```hcl
output "id" { value = azurerm_mssql_managed_instance.main.id }
output "name" { value = azurerm_mssql_managed_instance.main.name }
output "fqdn" { value = azurerm_mssql_managed_instance.main.fqdn }
```

- [ ] **Step 4: Implement Data Factory scaffold**

Create `terraform/modules/data_factory/variables.tf`:

```hcl
variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "log_analytics_workspace_id" { type = string }
variable "tags" { type = map(string) }
```

Create `terraform/modules/data_factory/main.tf`:

```hcl
resource "azurerm_data_factory" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  identity {
    type = "SystemAssigned"
  }

  managed_virtual_network_enabled = true
  public_network_enabled          = false
  tags                            = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_data_factory.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "PipelineRuns"
  }

  enabled_log {
    category = "ActivityRuns"
  }

  enabled_log {
    category = "TriggerRuns"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
```

Create `terraform/modules/data_factory/outputs.tf`:

```hcl
output "id" { value = azurerm_data_factory.main.id }
output "name" { value = azurerm_data_factory.main.name }
output "principal_id" { value = azurerm_data_factory.main.identity[0].principal_id }
```

- [ ] **Step 5: Add root variables for SQL admin**

Append to `terraform/variables.tf`:

```hcl
variable "sql_mi_administrator_login" {
  description = "Temporary SQL MI administrator login. Replace with Entra-only access after bootstrap where possible."
  type        = string
  default     = "sqlmiadmin"
}

variable "sql_mi_administrator_password" {
  description = "Temporary SQL MI administrator password. Supply via TF_VAR_sql_mi_administrator_password."
  type        = string
  sensitive   = true
}
```

- [ ] **Step 6: Wire baseline service modules in root**

Append to `terraform/main.tf`:

```hcl
data "azurerm_client_config" "current" {}

module "key_vault" {
  source                     = "./modules/key_vault"
  name                       = module.naming.key_vault
  location                   = var.location
  resource_group_name        = module.foundation.core_resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  log_analytics_workspace_id = module.foundation.log_analytics_workspace_id
  tags                       = local.common_tags
}

module "storage" {
  source                     = "./modules/storage"
  location                   = var.location
  resource_group_name        = module.foundation.data_resource_group_name
  adls_name                  = module.naming.adls_account
  blob_name                  = module.naming.blob_account
  is_prod                    = local.is_prod
  log_analytics_workspace_id = module.foundation.log_analytics_workspace_id
  tags                       = local.common_tags
}

module "sql_mi" {
  source                     = "./modules/sql_mi"
  name                       = module.naming.sql_managed_instance
  location                   = var.location
  resource_group_name        = module.foundation.data_resource_group_name
  subnet_id                  = module.network.sql_mi_subnet_id
  administrator_login        = var.sql_mi_administrator_login
  administrator_password     = var.sql_mi_administrator_password
  log_analytics_workspace_id = module.foundation.log_analytics_workspace_id
  tags                       = local.common_tags
}

module "adf_ssis" {
  source                     = "./modules/data_factory"
  name                       = module.naming.adf_ssis
  location                   = var.location
  resource_group_name        = module.foundation.data_resource_group_name
  log_analytics_workspace_id = module.foundation.log_analytics_workspace_id
  tags                       = local.common_tags
}

module "adf_general" {
  count                      = var.enable_native_adf ? 1 : 0
  source                     = "./modules/data_factory"
  name                       = module.naming.adf_general
  location                   = var.location
  resource_group_name        = module.foundation.data_resource_group_name
  log_analytics_workspace_id = module.foundation.log_analytics_workspace_id
  tags                       = local.common_tags
}
```

## Task 5: Add Optional Analytics and Function App Scaffolds

**Files:**
- Create: `terraform/modules/analytics/main.tf`
- Create: `terraform/modules/analytics/variables.tf`
- Create: `terraform/modules/analytics/outputs.tf`
- Create: `terraform/modules/function_app/main.tf`
- Create: `terraform/modules/function_app/variables.tf`
- Create: `terraform/modules/function_app/outputs.tf`
- Modify: `terraform/main.tf`

- [ ] **Step 1: Implement analytics module inputs**

Create `terraform/modules/analytics/variables.tf`:

```hcl
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "aml_name" { type = string }
variable "databricks_name" { type = string }
variable "storage_account_id" { type = string }
variable "key_vault_id" { type = string }
variable "log_analytics_workspace_id" { type = string }
variable "tags" { type = map(string) }
```

- [ ] **Step 2: Implement optional Azure ML and Databricks resources**

Create `terraform/modules/analytics/main.tf`:

```hcl
resource "azurerm_application_insights" "main" {
  name                = "${var.aml_name}-appi"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  tags                = var.tags
}

resource "azurerm_machine_learning_workspace" "main" {
  name                    = var.aml_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  application_insights_id = azurerm_application_insights.main.id
  key_vault_id            = var.key_vault_id
  storage_account_id      = var.storage_account_id

  identity {
    type = "SystemAssigned"
  }

  public_network_access_enabled = false
  tags                          = var.tags
}

resource "azurerm_databricks_workspace" "lab" {
  name                          = var.databricks_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = "premium"
  public_network_access_enabled = false
  tags                          = var.tags
}
```

Create `terraform/modules/analytics/outputs.tf`:

```hcl
output "aml_workspace_id" { value = azurerm_machine_learning_workspace.main.id }
output "databricks_workspace_id" { value = azurerm_databricks_workspace.lab.id }
```

- [ ] **Step 3: Implement Function App scaffold**

Create `terraform/modules/function_app/variables.tf`:

```hcl
variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "storage_account_name" { type = string }
variable "tags" { type = map(string) }
```

Create `terraform/modules/function_app/main.tf`:

```hcl
resource "azurerm_service_plan" "main" {
  name                = "${var.name}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = var.tags
}

resource "azurerm_linux_function_app" "main" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = azurerm_service_plan.main.id
  storage_account_name       = var.storage_account_name
  functions_extension_version = "~4"
  https_only                 = true
  tags                       = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }
}
```

Create `terraform/modules/function_app/outputs.tf`:

```hcl
output "id" { value = azurerm_linux_function_app.main.id }
output "principal_id" { value = azurerm_linux_function_app.main.identity[0].principal_id }
```

- [ ] **Step 4: Wire optional modules**

Append to `terraform/main.tf`:

```hcl
module "analytics" {
  count                      = var.enable_analytics ? 1 : 0
  source                     = "./modules/analytics"
  location                   = var.location
  resource_group_name        = module.foundation.analytics_resource_group_name
  aml_name                   = module.naming.aml_workspace
  databricks_name            = module.naming.databricks
  storage_account_id         = module.storage.blob_id
  key_vault_id               = module.key_vault.id
  log_analytics_workspace_id = module.foundation.log_analytics_workspace_id
  tags                       = local.common_tags
}

module "function_app" {
  count                = var.enable_function_app ? 1 : 0
  source               = "./modules/function_app"
  name                 = module.naming.function_app
  location             = var.location
  resource_group_name  = module.foundation.data_resource_group_name
  storage_account_name = module.storage.blob_name
  tags                 = local.common_tags
}
```

## Task 6: Add Outputs and CI Validation

**Files:**
- Modify: `terraform/outputs.tf`
- Create: `pipelines/azure-pipelines-validate.yml`

- [ ] **Step 1: Add root outputs**

Create `terraform/outputs.tf`:

```hcl
output "resource_groups" {
  value = {
    core      = module.foundation.core_resource_group_name
    data      = module.foundation.data_resource_group_name
    analytics = module.foundation.analytics_resource_group_name
  }
}

output "key_vault_uri" {
  value = module.key_vault.vault_uri
}

output "sql_mi_fqdn" {
  value = module.sql_mi.fqdn
}

output "data_factory_ssis_name" {
  value = module.adf_ssis.name
}

output "storage_accounts" {
  value = {
    adls = module.storage.adls_name
    blob = module.storage.blob_name
  }
}
```

- [ ] **Step 2: Create Azure DevOps validation pipeline**

Create `pipelines/azure-pipelines-validate.yml`:

```yaml
trigger:
  branches:
    include:
      - main
      - develop

pr:
  branches:
    include:
      - main
      - develop

pool:
  vmImage: ubuntu-latest

steps:
  - task: TerraformInstaller@1
    inputs:
      terraformVersion: latest

  - script: ./scripts/validate.sh
    displayName: Validate Terraform
```

- [ ] **Step 3: Run validation**

Run:

```bash
./scripts/validate.sh
```

Expected:

```text
Success! The configuration is valid.
```

## Task 7: Gap Review Before First Deployment

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add deployment notes to README**

Append to `README.md`:

```markdown
## Pre-Deployment Decisions

Confirm these before the first `terraform apply`:

- Whether the asset code must be `ppuk` or `puk`.
- Subscription IDs and remote backend storage for each environment.
- CIDR ranges that do not conflict with PPG hub/spoke networking.
- Required private DNS zone ownership model.
- PPG Calandra mandatory tag names and allowed values.
- Whether SQL MI bootstrap should allow temporary SQL auth or Entra-only setup.
- Whether production requires SQL MI geo-replication immediately.
- Whether Microsoft Purview is existing and should be integrated by ID instead of provisioned.
- Sentinel / Log Analytics workspace target if centralised outside this subscription.
- Exact Azure DevOps project and service connection names.
```

- [ ] **Step 2: Run final format and validation**

Run:

```bash
./scripts/validate.sh
```

Expected:

```text
Success! The configuration is valid.
```

## Spec Coverage Check

Covered by this plan:

- Landing zone IaC setup for required Azure services.
- Naming convention and environment separation.
- UK South deployment.
- Managed identities, RBAC-ready resources, private access defaults.
- Key Vault, SQL MI, ADF, storage, Log Analytics, diagnostics.
- Optional Azure ML, Databricks LAB, Function App, and native ADF scaffolding.
- Cost and ownership tagging.
- Local and CI validation.

Intentionally not covered:

- Any SQL Server to SQL MI migration work.
- Any SSIS package deployment or SSISDB package configuration.
- Any ETL pipeline rewrite.
- Any production data copy.
- Any Power BI report migration.
- Any source-system connectivity implementation beyond landing zone primitives.

Known follow-up design decisions:

- Confirm `ppuk` vs `puk` asset code.
- Confirm central hub networking and private DNS model.
- Confirm whether a central Log Analytics / Sentinel workspace already exists.
- Confirm exact Calandra tag policy.
- Confirm final environment subscription model.
- Confirm whether Azure DevOps resources are managed outside Terraform.
