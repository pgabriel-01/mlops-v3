---
title: Scenarios
weight: 20
---

# AML scenarios

Pick one with `scenario:` in the inputs file. List them with `Get-MLOpsScenario`; scaffold an inputs file with
`New-MLOpsInputFile -Scenario <id|number> -Path inputs.yaml -Iac terraform|bicep -Cicd github|azdo`.

| # | Id | Network | Serving | Adds |
|---|---|---|---|---|
| 1 | [`basic-public`](01-basic-public.md) | public | none | Workspace, storage, Key Vault, ACR, App Insights, CPU cluster, training pipeline |
| 2 | [`managed-vnet-internet`](02-managed-vnet-internet.md) | managed VNet, internet outbound | online | Private endpoints, public access disabled |
| 3 | [`managed-vnet-approved`](03-managed-vnet-approved.md) | managed VNet, approved outbound only | online | FQDN/service-tag allow-list (`allowed_outbound_fqdns`) |
| 4 | [`byo-vnet`](04-byo-vnet.md) | your VNet (created) | online | Spoke VNet, subnets, private DNS zones, private endpoints (`vnet_address_space`) |
| 5 | [`batch-scoring`](05-batch-scoring.md) | public | batch | Batch endpoint and deployment, nightly scoring workflow |
| 6 | [`online-bluegreen`](06-online-bluegreen.md) | public | online (blue/green) | Deploy workflow shifts 10% then 100% of traffic and retires the old deployment |
| 7 | [`feature-store`](07-feature-store.md) | public | online | Managed feature store workspace |
| 8 | [`registry-promotion`](08-registry-promotion.md) | public | online | Shared AML registry in the first environment, `ml-promote` workflow, deploy from the registry |
| 9 | [`governance`](09-governance.md) | public | online | Diagnostics, budget alerts (`budget_amount`, `alert_emails`), lock, policy |
| 10 | [`genai-foundry`](10-genai-foundry.md) | public | none | AI Foundry hub, AI Services account and project |
| 11 | [`existing-platform`](11-existing-platform.md) | existing subnet and DNS | online | Reuses `existing_platform` subnet, private DNS zones and Log Analytics; governance on |

## Choosing a scenario

| Start here if... | Scenario | Relative fixed cost |
|---|---|---|
| You are learning or prototyping and data is not sensitive | 1 `basic-public` | Lowest (about $60/month for 3 environments) |
| You need real-time scoring with a REST endpoint | 6 `online-bluegreen` (safe rollouts) or 2-4 (private) | Low to medium |
| Scoring runs on a schedule, not in real time | 5 `batch-scoring` | Low (compute only while running) |
| Security requires no public access, and you have no existing network | 2 `managed-vnet-internet`, or 3 for locked-down egress | Medium; 3 adds a managed firewall, which is the largest fixed cost |
| You must control the network yourself | 4 `byo-vnet` | Medium (private endpoints and DNS zones) |
| A platform team already owns the subnet, DNS and Log Analytics | 11 `existing-platform` | Medium; reuses shared services |
| Several teams share models across workspaces or environments | 8 `registry-promotion` | Low added cost |
| You need reusable features across models | 7 `feature-store` | Low added cost |
| Finance or audit needs budgets, policy and diagnostics | 9 `governance` | Low added cost |
| You are building generative AI apps | 10 `genai-foundry` | Depends on the models you deploy |

Costs are relative and exclude training compute and endpoint instance hours, which dominate once you deploy. The default is three environments (see [Environments and cost](../parameter-checklist.md)); set two to cut the fixed cost.

!!! tip
    Start with 1, prove the pipeline end to end, then change `scenario` and regenerate. Decide the network mode early: switching it on an existing workspace is a larger change than adding serving or governance, and this has not been tested here.

## Estimated fixed monthly cost

| # | Scenario | Fixed infrastructure / month | With one online instance per environment |
|---|---|---:|---:|
| 1 | [`basic-public`](01-basic-public.md) | 60.83 | 60.83 |
| 2 | [`managed-vnet-internet`](02-managed-vnet-internet.md) | 152.08 | 763.09 |
| 3 | [`managed-vnet-approved`](03-managed-vnet-approved.md) | 2,889.58 | 3,500.59 |
| 4 | [`byo-vnet`](04-byo-vnet.md) | 272.92 | 883.93 |
| 5 | [`batch-scoring`](05-batch-scoring.md) | 60.83 | 60.83 |
| 6 | [`online-bluegreen`](06-online-bluegreen.md) | 60.83 | 671.84 |
| 7 | [`feature-store`](07-feature-store.md) | 60.83 | 671.84 |
| 8 | [`registry-promotion`](08-registry-promotion.md) | 111.52 | 722.53 |
| 9 | [`governance`](09-governance.md) | 60.83 | 671.84 |
| 10 | [`genai-foundry`](10-genai-foundry.md) | 60.83 | 60.83 |
| 11 | [`existing-platform`](11-existing-platform.md) | 261.58 | 872.59 |

Region **westus**, **USD**, **3** environments, retrieved 2026-10-13.

!!! note
    Based on [Azure Retail Prices](https://learn.microsoft.com/rest/api/cost-management/retail-prices/azure-retail-prices) list prices, not your negotiated rates. Included: Container Registry, private endpoints (5 per environment) and private DNS zones (6 per environment) for BYO VNet, the managed-network Azure Firewall (Standard, scenario 3) and the shared registry (scenario 8). The last column adds one `Standard_DS3_v2` online-endpoint instance per environment. Not included: training compute (clusters scale to zero), Log Analytics and Application Insights ingestion, storage, data transfer, AI model usage, and the managed private endpoints that AML creates for managed VNets. Managed-network outbound rules were not priced individually. Treat these as order-of-magnitude figures; generate your own with `./scripts/Get-ScenarioCostEstimates.ps1 -Region <region> -Currency <code> -Environments <n> -AsMarkdown`.

## Notes

- Network modes other than `public` disable public access; run the pipelines on self-hosted agents that can reach the private endpoints.
- Scenarios 1 and 10 generate no serving workflow (`deploy_mode: none`).
- The training workload is the tabular taxi pack in every scenario; GenAI (10) provisions the platform only.
- Everything here is validated offline (render, `terraform validate`/`fmt`, `az bicep build`); nothing has been applied to a real subscription.

## Alignment with Microsoft guidance

- MLOps v2 solution accelerator and architecture: <https://learn.microsoft.com/azure/architecture/ai-ml/guide/machine-learning-operations-v2> and <https://github.com/Azure/mlops-v2>. This accelerator keeps its separation of infra, training pipeline and deployment pipeline, environment promotion and model registry gating.
- Managed network, secure workspace, endpoints, registries, feature store, monitoring and policy links are listed per scenario in `templates/scenarios.json` and in each generated README.
