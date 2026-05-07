# PPUK Landing Zone Codebase Explained Like I Am 10

## The Big Picture

Imagine we are building a new data playground in Azure.

The PDF is the instruction book. It says PPUK needs a safe, modern place where data tools can live. This repo turns that instruction book into Terraform code.

Terraform is like a careful robot builder. We tell it what Azure things we want, and it builds them the same way every time.

This code does **landing zone setup only**. That means it creates the Azure rooms, locks, roads, labels, and basic services. It does **not** move old data, deploy SSIS packages, rewrite ETL jobs, or migrate reports.

## What Is a Landing Zone?

A landing zone is the prepared space in Azure where applications and data services can safely land.

Think of it like preparing a school before students arrive:

- Classrooms are resource groups.
- Hallways are networks.
- Locked cupboards are Key Vault.
- School records are SQL Managed Instance.
- Delivery routes are Data Factory.
- Storage rooms are storage accounts.
- Security cameras are monitoring and logs.

The actual students and lessons are not moved in yet. We are only building the school.

## Why Azure Verified Modules?

Azure Verified Modules, or AVM, are ready-made Terraform building blocks from Azure.

Instead of hand-building every Azure service from scratch, we use these trusted blocks for the big parts:

- Resource groups
- Virtual network
- Log Analytics
- Key Vault
- Storage accounts
- SQL Managed Instance
- Data Factory
- Databricks
- Azure Machine Learning

This keeps the code closer to Azure best practice and easier to maintain.

## Folder Map

```text
.
├── README.md
├── docs/
├── pipelines/
├── scripts/
└── terraform/
```

## Root Files

### `README.md`

This is the front page of the repo.

It explains:

- What the repo is for
- What is in scope
- What is not in scope
- Which Azure Verified Modules are used
- How to validate the Terraform
- What decisions must be confirmed before deployment

### `.gitignore`

This tells Git which files should not be committed.

For example, Terraform creates local working folders and state files. Those should not be pushed accidentally.

### `Calandra Tier 1 Application - PPUK Data Platform Tech Requirements.pdf`

This is the source requirements document.

The Terraform was created from this PDF, but only for landing zone setup.

## Docs Folder

### `docs/superpowers/plans/2026-05-07-ppuk-landing-zone-setup.md`

This is the implementation plan.

It explains what we planned to build before writing the Terraform code.

### `docs/codebase-explained-like-im-10.md`

This file.

It explains the repo in simple words.

## Scripts Folder

### `scripts/validate.sh`

This checks whether Terraform is healthy.

It runs:

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

In simple words:

- `fmt` checks the code is neatly formatted.
- `init` downloads the Terraform modules and providers.
- `validate` checks the Terraform makes sense.

## Pipelines Folder

### `pipelines/azure-pipelines-validate.yml`

This is for Azure DevOps.

When someone opens a PR or pushes code, the pipeline can run the same validation script automatically.

It helps catch broken Terraform before it is merged.

## Terraform Folder

This is where the real infrastructure code lives.

### `terraform/versions.tf`

This says which Terraform and provider versions the repo expects.

It is like saying:

“Use the right tools before building.”

### `terraform/providers.tf`

This configures the Azure providers.

Providers are Terraform plugins that know how to talk to Azure.

This repo uses:

- `azurerm` for normal Azure resources
- `azapi` because some AVM modules use newer Azure APIs

### `terraform/variables.tf`

This lists the knobs people can turn.

Examples:

- Which environment are we deploying? `dev`, `test`, `uat`, `preprod`, or `prod`
- What Azure region? Default is `uksouth`
- What asset code? Default is `ppuk`
- Should optional analytics tools be deployed?
- What SQL MI size should be used?

Variables make the code reusable.

### `terraform/envs/*.tfvars`

These files give values for each environment.

For example:

- `dev.tfvars`
- `test.tfvars`
- `uat.tfvars`
- `preprod.tfvars`
- `prod.tfvars`

If we want to deploy dev, we use:

```bash
terraform plan -var-file=envs/dev.tfvars
```

If we want prod:

```bash
terraform plan -var-file=envs/prod.tfvars
```

### `terraform/locals.tf`

This creates common names and tags.

Names are important because the PDF gives a naming pattern:

```text
ppg-<service>-<asset>-<identifier>-<region>-<environment>-<count>
```

So this file builds names like:

```text
ppg-adf-ppuk-ssis-uks-dev-001
ppg-akv-ppuk-uks-dev-001
```

It also creates common tags like:

- application
- asset
- environment
- owner
- costCentre
- managedBy

Tags are like labels on boxes. They help people understand cost, ownership, and purpose.

### `terraform/main.tf`

This is the main build file.

It uses AVM modules to create the big Azure services:

- Resource groups
- Log Analytics workspace
- Virtual network and subnets
- Key Vault
- ADLS storage account
- Blob storage account
- SQL Managed Instance
- Data Factory for SSIS support
- Optional general-purpose Data Factory
- Optional Databricks LAB
- Optional Azure ML workspace

If the repo is the kitchen, `main.tf` is the recipe.

### `terraform/network-prereqs.tf`

This creates extra networking pieces needed before SQL Managed Instance can work.

SQL Managed Instance is picky. Its subnet needs supporting network rules and a route table.

This file creates:

- A network security group for SQL MI
- Required SQL MI inbound rules
- A deny-all inbound rule
- A SQL MI route table

These are helper parts around the AVM VNet module.

### `terraform/storage-lifecycle.tf`

This creates a lifecycle policy for the AAE Blob Storage account.

The PDF says AAE project data should be cost-managed over time.

This file says:

- Move data to Cool storage after 180 days
- Move data to Archive storage after 730 days

That means old data gets cheaper to keep.

### `terraform/adls-filesystems.tf`

This creates folders/filesystems inside the ADLS Gen2 storage account:

- `landing`
- `bronze`
- `curated`

Think of these as shelves in a data storage room.

They prepare common lakehouse-style areas without moving any real business data yet.

### `terraform/outputs.tf`

This prints useful values after Terraform runs.

Examples:

- Resource group names
- Log Analytics workspace ID
- Virtual network ID
- Key Vault ID
- SQL Managed Instance ID
- Data Factory ID
- Storage account names

Outputs are like the receipt after building.

### `terraform/.terraform.lock.hcl`

This locks provider versions.

It helps different people and pipelines use the same Terraform provider versions, so the code behaves consistently.

## What Gets Built?

Here is the simple version:

```text
Azure subscription
└── Resource groups
    ├── Core
    │   ├── Virtual network
    │   ├── Subnets
    │   ├── Log Analytics
    │   └── Key Vault
    ├── Data
    │   ├── SQL Managed Instance
    │   ├── Data Factory
    │   ├── ADLS Gen2 storage
    │   └── Blob storage
    └── Analytics
        ├── Databricks LAB, optional
        └── Azure ML, optional
```

## What Does Not Get Built?

This repo does not do these things:

- It does not migrate old SQL Server data.
- It does not deploy SSIS packages.
- It does not rewrite SSIS into ADF pipelines.
- It does not move production data.
- It does not create Power BI reports.
- It does not configure business models.

Those would be later project phases.

## How the Files Work Together

The flow is:

1. `versions.tf` says which Terraform tools are allowed.
2. `providers.tf` tells Terraform how to talk to Azure.
3. `variables.tf` defines the inputs.
4. `envs/*.tfvars` gives environment-specific values.
5. `locals.tf` builds standard names and tags.
6. `network-prereqs.tf` creates SQL MI network helper pieces.
7. `main.tf` creates the main Azure services with AVM.
8. `adls-filesystems.tf` creates ADLS shelves.
9. `storage-lifecycle.tf` adds the Blob lifecycle rule.
10. `outputs.tf` prints useful results.

## How to Validate It

Run:

```bash
./scripts/validate.sh
```

If everything is okay, Terraform says:

```text
Success! The configuration is valid.
```

## Important Things Still To Confirm

Before real deployment, confirm:

- Should the asset code be `ppuk` or `puk`?
- Which Azure subscription should each environment use?
- What CIDR ranges should the VNet use?
- Is there already a central Log Analytics or Sentinel workspace?
- What exact Calandra tags are mandatory?
- Should SQL MI use temporary SQL admin login or Entra-only setup?
- Should production SQL MI use geo-replication from day one?

## One-Sentence Summary

This repo builds the safe Azure foundation for the PPUK data platform, using Azure Verified Modules for the main services, while carefully avoiding migration work.
