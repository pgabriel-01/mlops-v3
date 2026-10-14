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

Each decision maps to a key in `inputs.yaml`. The [parameter checklist](parameter-checklist.md) lists them all in one place, and the [decision flow](decision-flow.md) shows how the choices connect.

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

### Decision 10 - Choose the bootstrap networking

The bootstrap creates the Terraform state storage account, and your pipelines need to reach it. Choose how:

| Option | Inputs | Use when |
|---|---|---|
| Public networking with GitHub-hosted runners (default) | `use_private_networking: false`, `runner_label: ubuntu-latest` | Trials, and subscriptions whose policy allows a public, Entra-only state endpoint |
| Public networking with your own self-hosted runners | `use_private_networking: false`, `runner_label: <your label>` | You already run runners (for example on AKS with ARC) that can reach the state storage |
| Private networking with accelerator-deployed runners (GitHub only) | `use_private_networking: true`, optional `runners_vnet_address_space` | Policy disables public access to storage. The bootstrap deploys a VNet, Azure Container Instances runners and a private endpoint for state, and sets `runner_label` to `self-hosted` |

Self-hosted runners are ignored unless the label points at them. Azure DevOps managed pools are not automated yet; point the generated pipelines at your own agent pool. Review `runners_vnet_address_space` (default `10.250.0.0/24`) so it does not overlap your corporate or Azure ranges. See [known issues](../known-issues.md) for the private runner details.

Fill in `use_private_networking`, `runners_vnet_address_space` and `runner_label`. The [decision flow](decision-flow.md) walks through the choice.

### Decision 11 - Governance

`budget_amount` and `alert_emails` for the governance scenarios.

### Decision 12 - Workloads

`workloads`: optional list of workload names (for example `[taxi, churn]`). All workloads share the one platform (a workspace per environment) and each gets its own `workloads/<name>/` folder, assets and pipelines. Omit it for a single workload at the repository root.

### Decision 13 - Repository and organisation

GitHub: `github_org`, `github_repo`. Azure DevOps: `azdo_org_url`, `azdo_project`.

## Next

Run `New-MLOpsInputFile -Scenario <id> -Path inputs.yaml`, fill in the values, then continue to [Phase 1 - Prerequisites](../prerequisites/_index.md).
