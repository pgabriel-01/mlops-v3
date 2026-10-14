---
title: "Phase 0 - Planning"
weight: 10
---

Plan your deployment by working through the decisions below.

{{% callout style="note" %}}
This phase is optional. If you already know what you want, skip to [Phase 1](../prerequisites/_index.md).
{{% /callout %}}
## Terms

- **Accelerator module**: the `MLOpsAccelerator` PowerShell module (`Deploy-MLOpsAccelerator`).
- **Inputs file**: the one `inputs.yaml` that drives everything.
- **Scenario**: one of 11 Azure ML network, serving and governance patterns.
- **Bootstrap**: the Terraform that creates the repository, environments, identity and Azure access before any ML infrastructure exists.
- **Generated project**: the repository the accelerator writes: infrastructure, CI/CD and ML workload.
- **Environment**: a full Azure ML workspace and its dependencies, one per stage (`dev`, `test`, `prod`).

## Skills that help

- Terraform or Bicep workflow: [Terraform fundamentals](https://aka.ms/tf/fundamentals), [Bicep learning path](https://learn.microsoft.com/training/paths/fundamentals-bicep/)
- Azure Machine Learning: [AML learning path](https://learn.microsoft.com/training/paths/build-ai-solutions-with-azure-ml-service/)
- CI/CD and git: [Introduction to DevOps](https://learn.microsoft.com/training/modules/introduction-to-devops/), [Introduction to git](https://learn.microsoft.com/training/modules/intro-to-git/)

## Decisions

Each decision maps to a key in `inputs.yaml`. The [parameter checklist](parameter-checklist.md) lists them all in one place.

### Decision 1 - Infrastructure as Code tooling

`iac`: `terraform` or `bicep`. Both build on Azure Verified Modules and render the same scenarios. The bootstrap is always Terraform.

### Decision 2 - Version control system

`cicd`: `github` (GitHub Actions) or `azdo` (Azure DevOps Pipelines). Other systems: use the generated files and wire your own pipeline.

### Decision 3 - Scenario

`scenario`: pick from the [scenarios](../scenarios/_index.md) table. Network mode drives most of the cost and prerequisites. When unsure, start with `basic-public` and move later.

### Decision 4 - Azure region

`location`: where every environment is deployed. Check quota for the compute you will use.

### Decision 5 - Subscription and tenant

`subscription_id`, `tenant_id`. One subscription hosts all environments. Separate subscriptions per environment are not an input yet.

### Decision 6 - Environments

`environments`: default `dev`, `test`, `prod`. Use `[dev, prod]` for a trial or small team. Each environment is a complete workspace, so cost scales with the count. See [cost estimates](../scenarios/_index.md#estimated-fixed-monthly-cost).

### Decision 7 - Naming and tags

`project_name` (3-10 lowercase alphanumerics) seeds resource names. `tags` are applied to everything.

### Decision 8 - Data source

`data_source`: `taxi-csv` or `taxi-parquet` (bundled MLTable samples) or `adls` (your CSV in ADLS Gen2). See [data sources](data-sources.md).

### Decision 9 - Networking inputs

Only for some scenarios: `vnet_address_space` (BYO VNet), `allowed_outbound_fqdns` (managed approved outbound), and `existing_platform` (existing platform). Pick address space that does not overlap your corporate or Azure ranges.

### Decision 10 - Governance

`budget_amount` and `alert_emails` for the governance scenarios.

### Decision 11 - Repository and organisation

GitHub: `github_org`, `github_repo`. Azure DevOps: `azdo_org_url`, `azdo_project`.

## Next

Run `New-MLOpsInputFile -Scenario <id> -Path inputs.yaml`, fill in the values, then continue to [Phase 1 - Prerequisites](../prerequisites/_index.md).
