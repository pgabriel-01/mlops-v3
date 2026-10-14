---
title: "Parameter checklist"
weight: 2
---

Work through this before running `Deploy-MLOpsAccelerator`.

## Always
- [ ] `project_name` (3-10 lowercase alphanumerics)
- [ ] `location`, `subscription_id`, `tenant_id`
- [ ] `scenario` (see [scenarios](../scenarios/_index.md))
- [ ] `iac`: `terraform` or `bicep`
- [ ] `cicd`: `github` (`github_org`, `github_repo`) or `azdo` (`azdo_org_url`, `azdo_project`)
- [ ] `environments`: default `dev`, `test`, `prod`; any ordered subset of those (promotion and approvals follow the order)
- [ ] `tags`

## By scenario
- [ ] 3: `allowed_outbound_fqdns`
- [ ] 4: `vnet_address_space`
- [ ] 9, 11: `budget_amount`, `alert_emails`
- [ ] 11: `existing_platform.subnet_id`, `.log_analytics_workspace_id`, `.private_dns_zone_ids` (blob, file, vault, acr, aml_api, aml_notebooks)

## Prerequisites
See [Phase 1 - Prerequisites](../prerequisites/_index.md): tools, Azure permissions and resource providers, GitHub or Azure DevOps token, quota, and self-hosted agents for private scenarios. `Test-MLOpsAcceleratorRequirement` checks what it can.

## Data source
- [ ] `data_source: taxi-csv` (default), `taxi-parquet` (both bundled MLTable samples) or `adls` (your own CSV in ADLS Gen2)
- [ ] For `adls`: grant the AML workspace identity **Storage Blob Data Reader** on the account (not created by the IaC)
- [ ] Snowflake / Azure SQL: land the data in ADLS first (ADF or Fabric), then use `adls`. See [data-sources.md](data-sources.md)

## Environments and cost
- [ ] Default is three environments (`dev`, `test`, `prod`). Each one is a full AML workspace with its dependencies; private scenarios add networking and `managed-vnet-approved` adds a managed firewall per environment.
- [ ] For a trial or small team use `environments: [dev, prod]`; promotion and approvals follow the order you list.
