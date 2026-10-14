---
title: "7 - Managed feature store"
weight: 7
---

Adds an AML managed feature store workspace. Parquet data source arrives with the feature-store workload pack.

| | |
|---|---|
| Id | `feature-store` |
| Network | public |
| Serving | online |
| Adds | Managed feature store workspace |
| IaC / CI/CD | Terraform or Bicep; GitHub or Azure DevOps |

Adds a managed feature store workspace alongside the project workspace.

## Use it

```powershell
New-MLOpsInputFile -Scenario feature-store -Path inputs.yaml -Iac terraform -Cicd github
```

See the [cost estimates](_index.md#estimated-fixed-monthly-cost) and the [prerequisites](../prerequisites/_index.md).

## Microsoft documentation

- <https://learn.microsoft.com/azure/machine-learning/concept-what-is-managed-feature-store>
