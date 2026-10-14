---
title: "2 - Secure: managed VNet, internet outbound"
weight: 2
---

Workspace managed virtual network (AllowInternetOutbound), private endpoints, public access disabled.

| | |
|---|---|
| Id | `managed-vnet-internet` |
| Network | managed VNet, internet outbound |
| Serving | online |
| Adds | Private endpoints, public access disabled |
| IaC / CI/CD | Terraform or Bicep; GitHub or Azure DevOps |

Public network access is disabled on the workspace and its dependencies. Outbound traffic from jobs goes to the internet through the managed network.

## Use it

```powershell
New-MLOpsInputFile -Scenario managed-vnet-internet -Path inputs.yaml -Iac terraform -Cicd github
```

{{% callout style="note" %}}
Pipelines that touch the workspace need self-hosted agents or runners with network access to it.
{{% /callout %}}
See the [cost estimates](_index.md#estimated-fixed-monthly-cost) and the [prerequisites](../prerequisites/_index.md).

## Microsoft documentation

- <https://learn.microsoft.com/azure/machine-learning/how-to-managed-network>
