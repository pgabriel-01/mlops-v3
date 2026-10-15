---
title: "11 - Integrate with an existing platform landing zone"
weight: 11
---

Reuses a supplied subnet, private DNS zones and Log Analytics workspace instead of creating them.

| | |
|---|---|
| Id | `existing-platform` |
| Network | existing subnet and DNS |
| Serving | online |
| Adds | Reuses `existing_platform` subnet, private DNS zones and Log Analytics; governance on |
| IaC and CI/CD | Terraform or Bicep; GitHub or Azure DevOps |

The accelerator creates no network resources. The workspace and its private endpoints use the subnet, private DNS zones and Log Analytics workspace your platform team provides.

## Use it

```powershell
New-MLOpsInputFile -Scenario existing-platform -Path inputs.yaml -Iac terraform -Cicd github
```

## Inputs to review

- `existing_platform`: see [Options](../options/_index.md)
- `budget_amount`: see [Options](../options/_index.md)
- `alert_emails`: see [Options](../options/_index.md)

{{% callout style="note" %}}
Pipelines that touch the workspace need self-hosted agents or runners with network access to it.
{{% /callout %}}

See the [cost estimates](_index.md#estimated-fixed-monthly-cost) and the [prerequisites](../prerequisites/_index.md).

## Microsoft documentation

- <https://learn.microsoft.com/azure/architecture/ai-ml/architecture/baseline-azure-ai-foundry-landing-zone>
