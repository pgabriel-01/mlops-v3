---
title: "9 - Monitoring and governance"
weight: 9
---

Diagnostic settings, budget alerts, resource locks and Azure Policy assignments around the workspace.

| | |
|---|---|
| Id | `governance` |
| Network | public |
| Serving | online |
| Adds | Diagnostics, budget alerts (`budget_amount`, `alert_emails`), resource lock, policy |
| IaC and CI/CD | Terraform or Bicep; GitHub or Azure DevOps |

Adds diagnostics to Log Analytics, a monthly budget with email alerts, a resource lock and a policy assignment per environment.

## Use it

```powershell
New-MLOpsInputFile -Scenario governance -Path inputs.yaml -Iac terraform -Cicd github
```

## Inputs to review

- `budget_amount`: see [Options](../options/_index.md)
- `alert_emails`: see [Options](../options/_index.md)

See the [cost estimates](_index.md#estimated-fixed-monthly-cost) and the [prerequisites](../prerequisites/_index.md).

## Microsoft documentation

- <https://learn.microsoft.com/azure/machine-learning/how-to-monitor-azure-machine-learning>
- <https://learn.microsoft.com/azure/machine-learning/how-to-integrate-azure-policy>
