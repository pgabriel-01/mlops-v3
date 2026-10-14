---
title: "4 - Secure: bring-your-own VNet"
weight: 4
---

Spoke VNet, subnets, private DNS zones and private endpoints for all workspace dependencies.

| | |
|---|---|
| Id | `byo-vnet` |
| Network | your VNet (created) |
| Serving | online |
| Adds | Spoke VNet, subnets, private DNS zones, private endpoints (`vnet_address_space`) |
| IaC / CI/CD | Terraform or Bicep; GitHub or Azure DevOps |

You own the network: the accelerator creates a spoke VNet, subnets, private DNS zones and private endpoints. No NSGs are created on the subnets; add them to match your standards.

## Use it

```powershell
New-MLOpsInputFile -Scenario byo-vnet -Path inputs.yaml -Iac terraform -Cicd github
```

## Inputs to review

- `vnet_address_space`: see [Options](../options/_index.md)

{{% callout style="note" %}}
Pipelines that touch the workspace need self-hosted agents or runners with network access to it.
{{% /callout %}}
See the [cost estimates](_index.md#estimated-fixed-monthly-cost) and the [prerequisites](../prerequisites/_index.md).

## Microsoft documentation

- <https://learn.microsoft.com/azure/machine-learning/how-to-network-security-overview>
