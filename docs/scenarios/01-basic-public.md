---
title: "1 - Basic, public endpoints"
weight: 1
---

Workspace, storage, Key Vault, Azure Container Registry, Application Insights and a compute cluster. Training pipeline only, with public endpoints.

| | |
|---|---|
| Id | `basic-public` |
| Network | public |
| Serving | none |
| Adds | Workspace, storage, Key Vault, Azure Container Registry, Application Insights, CPU cluster, training pipeline |
| IaC and CI/CD | Terraform or Bicep; GitHub or Azure DevOps |

## Use it

```powershell
New-MLOpsInputFile -Scenario basic-public -Path inputs.yaml -Iac terraform -Cicd github
```

See the [cost estimates](_index.md#estimated-fixed-monthly-cost) and the [prerequisites](../prerequisites/_index.md).

## Microsoft documentation

- <https://learn.microsoft.com/azure/machine-learning/concept-azure-machine-learning-architecture>
- <https://learn.microsoft.com/azure/architecture/ai-ml/guide/machine-learning-operations-v2>
