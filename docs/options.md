# Options

Every option is a change to `inputs.yaml` followed by a regenerate, or a small edit to the generated files. This page shows which.

## How to change an option

1. Edit `inputs.yaml`.
2. Validate: `Test-MLOpsAcceleratorInput -InputFile inputs.yaml`.
3. Regenerate over an existing project (commit first, then review the diff):

```powershell
Deploy-MLOpsAccelerator -InputFile inputs.yaml -OutputPath ./my-mlops -Upgrade
```

Add `-Deploy` only if you also need to re-run the bootstrap (new repo, environments or identity). Changes to the workload and infrastructure are rolled out by the pipelines after you merge to `main`.

!!! warning
    Regenerating overwrites files. Anything you edited by hand in the generated project is replaced, so keep local edits small and review the diff.

## Options

1. [Use two environments instead of three](#two-environments)
2. [Choose Terraform or Bicep](#terraform-or-bicep)
3. [Choose GitHub or Azure DevOps](#github-or-azure-devops)
4. [Use your own data from ADLS](#your-own-data-adls)
5. [Allow extra outbound hosts (scenario 3)](#outbound-allow-list)
6. [Set the VNet address space (scenario 4)](#vnet-address-space)
7. [Reuse an existing platform landing zone (scenario 11)](#existing-platform)
8. [Budget alerts (scenarios 9 and 11)](#budget-alerts)
9. [Tags](#tags)
10. [Change compute and endpoint sizes](#compute-sizes)
11. [Switch scenario later](#switch-scenario)

### Two environments

```yaml
environments: [dev, prod]
```

Any ordered subset of `dev`, `test`, `prod`; promotion and approvals follow the order. Each environment is a full workspace, so this roughly cuts the fixed cost by a third (see [scenarios](scenarios.md)).

### Terraform or Bicep

```yaml
iac: bicep        # or terraform
```

Both build on Azure Verified Modules and produce the same resources. The bootstrap (repo, identity, state) is always Terraform regardless of this setting.

### GitHub or Azure DevOps

```yaml
cicd: github
github_org: contoso
github_repo: mlops-demo
# or
cicd: azdo
azdo_org_url: https://dev.azure.com/contoso
azdo_project: mlops
```

Azure DevOps pipelines are generated under `pipelines/` and must be registered manually (see [Run](run.md)).

### Your own data (ADLS)

```yaml
data_source: adls
adls:
  account_name: stcontosodata
  container: raw
  path: taxi/trips.csv      # a CSV with the same columns as the taxi sample
```

The datastore uses identity-based access; grant the workspace identity **Storage Blob Data Reader** (`Grant-MLOpsStorageAccess` does this). Snowflake and Azure SQL: land the data in ADLS first, see [data sources](data-sources.md).

### Outbound allow-list

Scenario 3 only. The default allows `pypi.org`, `files.pythonhosted.org`, `*.anaconda.com` and `conda.anaconda.org`. Replace it with exactly what your environment needs:

```yaml
allowed_outbound_fqdns:
  - pypi.org
  - files.pythonhosted.org
  - internal-mirror.contoso.com
```

Fewer hosts is safer, but training jobs that install packages fail if a host is missing.

### VNet address space

Scenario 4 only. Pick a range that does not overlap your corporate or hub networks:

```yaml
vnet_address_space: 10.20.0.0/16
```

### Existing platform

Scenario 11 only. Supply IDs from your platform team; no network, DNS zones or Log Analytics are created:

```yaml
existing_platform:
  subnet_id: /subscriptions/.../subnets/snet-aml
  log_analytics_workspace_id: /subscriptions/.../workspaces/log-platform
  private_dns_zone_ids:
    blob: /subscriptions/.../privateDnsZones/privatelink.blob.core.windows.net
    # file, vault, acr, aml_api, aml_notebooks
```

### Budget alerts

```yaml
budget_amount: 500        # USD per month, per environment resource group
alert_emails: [mlops-team@contoso.com]
```

### Tags

```yaml
tags:
  costcenter: "1234"
  owner: mlops-team
```

Applied to every resource group and resource.

### Compute sizes

Sizes are not inputs yet. Edit the generated files and keep them out of regeneration by committing your change after each `-Upgrade` review:

| What | File | Default |
|---|---|---|
| Training cluster | `infra/main.tf` (Terraform) or `infra/workload.bicep` (`vm_size`/`vmSize`, max node count) | `Standard_DS3_v2`, 0 to 4 nodes |
| Online endpoint | `mlops/azureml/online-deployment.yml` (`instance_type`, `instance_count`) | `Standard_DS3_v2`, 1 |
| Batch endpoint | `mlops/azureml/batch-deployment.yml` (`instance_count`) | 1 |

Making these inputs is on the to-do list.

### Switch scenario

Change `scenario` and regenerate. Adding serving, a registry, a feature store or governance is a small change. Changing the network mode of an existing workspace is a bigger one and has not been tested; for anything beyond a trial, plan on a new workspace.

## All inputs

| Input | Type | Default | Notes |
|---|---|---|---|
| `project_name` | string | required | 3-10 lowercase alphanumerics, used in resource names |
| `location` | string | required | Azure region, e.g. `eastus2` |
| `subscription_id`, `tenant_id` | string | required | |
| `iac` | `terraform` / `bicep` | required | |
| `cicd` | `github` / `azdo` | required | |
| `scenario` | string | required | See [scenarios](scenarios.md) |
| `data_source` | `taxi-csv` / `adls` | `taxi-csv` | |
| `environments` | list | `[dev, test, prod]` | Ordered subset |
| `tags` | map | `{}` | |
| `github_org`, `github_repo` | string | | `cicd: github` |
| `azdo_org_url`, `azdo_project` | string | | `cicd: azdo` |
| `workload` | `tabular` | `tabular` | `nlp`, `vision` planned |
| `vnet_address_space` | CIDR | `10.20.0.0/16` | Scenario 4 |
| `allowed_outbound_fqdns` | list | PyPI and conda hosts | Scenario 3 |
| `budget_amount` | number | 500 | Scenarios 9, 11 |
| `alert_emails` | list | `[]` | Scenarios 9, 11 |
| `existing_platform` | object | | Scenario 11 |
| `adls` | object | | `data_source: adls` |

The authoritative definition is `schema/inputs.schema.json`.
