---
title: "Options"
weight: 70
---

Every option is a change to `inputs.yaml` followed by a regenerate, or a small edit to the generated files. This page shows which.

## How to change an option

1. Edit `inputs.yaml`.
2. Validate: `Test-MLOpsAcceleratorInput -InputFile inputs.yaml`.
3. Regenerate over an existing project (commit first, then review the diff):

```powershell
Deploy-MLOpsAccelerator -InputFile inputs.yaml -OutputPath ./my-mlops -Upgrade
```

Add `-Deploy` only if you also need to re-run the bootstrap (new repo, environments or identity). Changes to the workload and infrastructure are rolled out by the pipelines after you merge to `main`.

{{% callout style="warning" %}}
Regenerating overwrites files. Anything you edited by hand in the generated project is replaced, so keep local edits small and review the diff.
{{% /callout %}}
## Options

1. [Two environments](01-two-environments.md)
2. [Terraform or Bicep](02-terraform-or-bicep.md)
3. [GitHub or Azure DevOps](03-github-or-azure-devops.md)
4. [Your own data (ADLS)](04-your-own-data-adls.md)
5. [Outbound allow-list](05-outbound-allow-list.md)
6. [VNet address space](06-vnet-address-space.md)
7. [Existing platform](07-existing-platform.md)
8. [Budget alerts](08-budget-alerts.md)
9. [Tags](09-tags.md)
10. [Compute sizes](10-compute-sizes.md)
11. [Switch scenario](11-switch-scenario.md)
12. [Policy mode](12-policy-mode.md)

## All inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `project_name` | string | required | 3-10 lowercase alphanumerics, used in resource names |
| `location` | string | required | Azure region, e.g. `eastus2` |
| `subscription_id`, `tenant_id` | string | required | |
| `iac` | `terraform` / `bicep` | required | |
| `cicd` | `github` / `azdo` | required | |
| `scenario` | string | required | See [scenarios](../scenarios/_index.md) |
| `data_source` | `taxi-csv` / `taxi-parquet` / `adls` | `taxi-csv` | |
| `environments` | list | `[dev, test, prod]` | Ordered subset |
| `tags` | map | `{}` | |
| `github_org`, `github_repo` | string | | `cicd: github` |
| `azdo_org_url`, `azdo_project` | string | | `cicd: azdo` |
| `workload` | `tabular` | `tabular` | `nlp`, `vision` planned |
| `vnet_address_space` | CIDR | `10.20.0.0/16` | Scenario 4 |
| `allowed_outbound_fqdns` | list | PyPI and conda hosts | Scenario 3 |
| `policy_mode` | `audit` / `deny` / `none` | `audit` (`none` for scenario 11) | [Azure Policy](../policy/_index.md) |
| `compute_vm_size` | string | `Standard_DS3_v2` | Training cluster and online endpoint VM size |
| `compute_max_nodes` | integer | 4 | Training cluster maximum nodes |
| `runner_label` | string | ubuntu-latest | GitHub `runs-on` label for generated workflows (self-hosted/private runners) |
| `approvers` | list | [] | GitHub usernames that must approve deployments to non-dev environments |
| `name_suffix` | string | derived | 4-6 lowercase alphanumerics; override to redeploy after a destroy (soft-delete holds names) |
| `keyvault_retention_days` | integer | 7 | Key Vault soft-delete retention (7-90, fixed at creation) |
| `budget_amount` | number | 500 | Scenarios 9, 11 |
| `alert_emails` | list | `[]` | Scenarios 9, 11 |
| `existing_platform` | object | | Scenario 11 |
| `adls` | object | | `data_source: adls` |

The authoritative definition is `schema/inputs.schema.json`.
