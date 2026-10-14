---
title: "3 - Secure: managed VNet, approved outbound only"
weight: 3
---

# 3 - Secure: managed VNet, approved outbound only

Workspace managed virtual network (AllowOnlyApprovedOutbound) with an FQDN/service-tag allow-list.

| | |
|---|---|
| Id | `managed-vnet-approved` |
| Network | managed VNet, approved outbound only |
| Serving | online |
| Adds | FQDN/service-tag allow-list (`allowed_outbound_fqdns`) |
| IaC / CI/CD | Terraform or Bicep; GitHub or Azure DevOps |

Outbound traffic is limited to the allow-list. A managed Azure Firewall is created per environment, which is the largest fixed cost of any scenario.

## Use it

```powershell
New-MLOpsInputFile -Scenario managed-vnet-approved -Path inputs.yaml -Iac terraform -Cicd github
```

## Inputs to review

- `allowed_outbound_fqdns`: see [Options](../options/index.md)

!!! note
    Pipelines that touch the workspace need self-hosted agents or runners with network access to it.

See the [cost estimates](index.md#estimated-fixed-monthly-cost) and the [prerequisites](../prerequisites/index.md).

## Microsoft documentation

- <https://learn.microsoft.com/azure/machine-learning/how-to-managed-network>
- <https://learn.microsoft.com/azure/machine-learning/how-to-access-azureml-behind-firewall>
