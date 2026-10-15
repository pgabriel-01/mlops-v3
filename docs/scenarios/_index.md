---
title: "Scenarios"
weight: 60
---

Pick one with `scenario:` in the inputs file. List them with `Get-MLOpsScenario`. Scaffold an inputs file with
`New-MLOpsInputFile -Scenario <id or number> -Path inputs.yaml -Iac <terraform or bicep> -Cicd <github or azdo>`.

| # | Id | Network | Serving | Adds |
|---|---|---|---|---|
| 1 | [`basic-public`](01-basic-public.md) | public | none | Workspace, storage, Key Vault, Azure Container Registry, Application Insights, CPU cluster, training pipeline |
| 2 | [`managed-vnet-internet`](02-managed-vnet-internet.md) | managed VNet, internet outbound | online | Private endpoints, public access disabled |
| 3 | [`managed-vnet-approved`](03-managed-vnet-approved.md) | managed VNet, approved outbound only | online | FQDN and service tag allow-list (`allowed_outbound_fqdns`) |
| 4 | [`byo-vnet`](04-byo-vnet.md) | your VNet (created) | online | Spoke VNet, subnets, private DNS zones, private endpoints (`vnet_address_space`) |
| 5 | [`batch-scoring`](05-batch-scoring.md) | public | batch | Batch endpoint and deployment, nightly scoring workflow |
| 6 | [`online-bluegreen`](06-online-bluegreen.md) | public | online (blue/green) | Deploy workflow shifts 10% then 100% of traffic and retires the old deployment |
| 7 | [`feature-store`](07-feature-store.md) | public | online | Managed feature store workspace |
| 8 | [`registry-promotion`](08-registry-promotion.md) | public | online | Shared Azure ML registry in the first environment, `ml-promote` workflow, deploy from the registry |
| 9 | [`governance`](09-governance.md) | public | online | Diagnostics, budget alerts (`budget_amount`, `alert_emails`), resource lock, policy |
| 10 | [`genai-foundry`](10-genai-foundry.md) | public | none | AI Foundry hub, AI Services account and project |
| 11 | [`existing-platform`](11-existing-platform.md) | existing subnet and DNS | online | Reuses `existing_platform` subnet, private DNS zones and Log Analytics; governance on |
| 12 | [`rag-llmops`](12-rag-llmops.md) | public | none | AI Foundry plus Azure AI Search, model deployments, sample index and an evaluation quality gate |

## Choosing a scenario

| Start here if... | Scenario | Relative fixed cost |
|---|---|---|
| You are learning or prototyping and data is not sensitive | 1 `basic-public` | Lowest (about $60 per month for 3 environments) |
| You need real-time scoring with a REST endpoint | 6 `online-bluegreen` (safe rollouts) or 2 to 4 (private) | Low to medium |
| Scoring runs on a schedule, not in real time | 5 `batch-scoring` | Low (compute only while running) |
| Security requires no public access, and you have no existing network | 2 `managed-vnet-internet`, or 3 for locked-down egress | Medium; 3 adds a managed firewall, which is the largest fixed cost |
| You must control the network yourself | 4 `byo-vnet` | Medium (private endpoints and DNS zones) |
| A platform team already owns the subnet, DNS and Log Analytics | 11 `existing-platform` | Medium; reuses shared services |
| Several teams share models across workspaces or environments | 8 `registry-promotion` | Low added cost |
| You need reusable features across models | 7 `feature-store` | Low added cost |
| Finance or audit needs budgets, policy and diagnostics | 9 `governance` | Low added cost |
| You are building generative AI apps | 10 `genai-foundry` | Depends on the models you deploy |
| You are building a chat app over your own documents with an evaluation gate | 12 `rag-llmops` | Adds Azure AI Search (basic tier is roughly 75 USD per month) plus model token use |

Costs are relative and exclude training compute and endpoint instance hours, which dominate once you deploy. The default is three environments (see the [parameter checklist](../planning/parameter-checklist.md)). Set two to cut the fixed cost.

{{% callout style="tip" %}}
Start with scenario 1, prove the pipeline end to end, then change `scenario` and regenerate. Decide the network mode early. Switching it on an existing workspace is a larger change than adding serving or governance, and it has not been tested.
{{% /callout %}}

## Estimated fixed monthly cost

| # | Scenario | Fixed infrastructure per month | With one online instance per environment |
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
| 12 | [`rag-llmops`](12-rag-llmops.md) | 282.02 | 282.02 |

Region `westus`, USD, 3 environments, retrieved 2026-10-15.

{{% callout style="note" %}}
Based on [Azure Retail Prices](https://learn.microsoft.com/rest/api/cost-management/retail-prices/azure-retail-prices) list prices, not your negotiated rates. Scenario 12 adds one Azure AI Search `basic` unit per environment (0.101 USD per hour, about 73.73 USD per month); model token usage is not included. Included: Azure Container Registry, private endpoints (5 per environment) and private DNS zones (6 per environment) for bring-your-own VNet, the managed network Azure Firewall (Standard, scenario 3) and the shared registry (scenario 8). The last column adds one `Standard_DS3_v2` online-endpoint instance per environment. Not included: training compute (clusters scale to zero), Log Analytics and Application Insights ingestion, storage, data transfer, AI model usage, and the managed private endpoints that Azure ML creates for managed VNets. Managed network outbound rules were not priced individually. Treat these as order-of-magnitude figures. Generate your own with `./scripts/Get-ScenarioCostEstimates.ps1 -Region <region> -Currency <code> -Environments <n> -AsMarkdown`.
{{% /callout %}}

## Notes

- Network modes other than `public` disable public access. Run the pipelines on self-hosted agents or runners that can reach the private endpoints.
- Scenarios 1 and 10 generate no serving workflow (`deploy_mode: none`).
- The training workload is the tabular taxi pack in every scenario. Scenario 10 (GenAI) provisions the platform only.
- Scenarios 1 to 12 are applied, verified and destroyed live on Terraform and Bicep by the `e2e.yml` workflow. Not verified live: bootstrap apply, private runners and state storage, Azure DevOps, separate plan and apply identities, Managed DevOps Pools, the `rai` option, the scenario 7 feature set pack and endpoint deployment.

## Alignment with Microsoft guidance

- MLOps v2 solution accelerator and architecture: <https://learn.microsoft.com/azure/architecture/ai-ml/guide/machine-learning-operations-v2> and <https://github.com/Azure/mlops-v2>. This accelerator keeps its separation of infrastructure, training pipeline and deployment pipeline, environment promotion and model registry gating.
- Managed network, secure workspace, endpoints, registries, feature store, monitoring and policy links are listed per scenario in `templates/scenarios.json` and in each generated README.
