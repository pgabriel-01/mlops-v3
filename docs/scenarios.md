# AML scenarios

Pick one with `scenario:` in the inputs file. List them with `Get-MLOpsScenario`; scaffold an inputs file with
`New-MLOpsInputFile -Scenario <id|number> -Path inputs.yaml -Iac terraform|bicep -Cicd github|azdo`.

| # | Id | Network | Serving | Adds |
|---|---|---|---|---|
| 1 | `basic-public` | public | none | Workspace, storage, Key Vault, ACR, App Insights, CPU cluster, training pipeline |
| 2 | `managed-vnet-internet` | managed VNet, internet outbound | online | Private endpoints, public access disabled |
| 3 | `managed-vnet-approved` | managed VNet, approved outbound only | online | FQDN/service-tag allow-list (`allowed_outbound_fqdns`) |
| 4 | `byo-vnet` | your VNet (created) | online | Spoke VNet, subnets, private DNS zones, private endpoints (`vnet_address_space`) |
| 5 | `batch-scoring` | public | batch | Batch endpoint and deployment, nightly scoring workflow |
| 6 | `online-bluegreen` | public | online (blue/green) | Deploy workflow shifts 10% then 100% of traffic and retires the old deployment |
| 7 | `feature-store` | public | online | Managed feature store workspace |
| 8 | `registry-promotion` | public | online | Shared AML registry in the first environment, `ml-promote` workflow, deploy from the registry |
| 9 | `governance` | public | online | Diagnostics, budget alerts (`budget_amount`, `alert_emails`), lock, policy |
| 10 | `genai-foundry` | public | none | AI Foundry hub, AI Services account and project |
| 11 | `existing-platform` | existing subnet and DNS | online | Reuses `existing_platform` subnet, private DNS zones and Log Analytics; governance on |

## Notes

- Network modes other than `public` disable public access; run the pipelines on self-hosted agents that can reach the private endpoints.
- Scenarios 1 and 10 generate no serving workflow (`deploy_mode: none`).
- The training workload is the tabular taxi pack in every scenario; GenAI (10) provisions the platform only.
- Everything here is validated offline (render, `terraform validate`/`fmt`, `az bicep build`); nothing has been applied to a real subscription.

## Alignment with Microsoft guidance

- MLOps v2 solution accelerator and architecture: <https://learn.microsoft.com/azure/architecture/ai-ml/guide/machine-learning-operations-v2> and <https://github.com/Azure/mlops-v2>. This accelerator keeps its separation of infra, training pipeline and deployment pipeline, environment promotion and model registry gating.
- Managed network, secure workspace, endpoints, registries, feature store, monitoring and policy links are listed per scenario in `templates/scenarios.json` and in each generated README.
