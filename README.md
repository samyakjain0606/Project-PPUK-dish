# PPUK Data Platform Landing Zone

Terraform infrastructure-as-code for the PPUK Tier 1 Data Platform landing zone described in the technical requirements PDF.

## Scope

This repository provisions Azure landing zone resources only. It does not migrate SQL databases, deploy SSIS packages, refactor ETL pipelines, move production data, or configure reports.

## Azure Verified Modules

The implementation uses Azure Verified Modules for the main Azure resources:

- Resource groups
- Virtual network and subnets
- Log Analytics workspace
- Key Vault
- Storage accounts
- SQL Managed Instance
- Data Factory
- Optional Azure Machine Learning workspace
- Optional Databricks workspace

Small prerequisite resources such as SQL MI subnet NSG rules, route tables, and storage lifecycle policy are implemented with native AzureRM resources where the AVM resource module is not the right boundary.

## Environments

- `dev`
- `test`
- `uat`
- `preprod`
- `prod`

## Validate

Terraform is required locally.

```bash
./scripts/validate.sh
```

## Plan

```bash
cd terraform
terraform init
terraform plan -var-file=envs/dev.tfvars
```

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
