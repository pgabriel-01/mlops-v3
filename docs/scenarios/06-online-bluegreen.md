---
title: "6 - Online endpoint with blue/green rollout"
weight: 6
---

Managed online endpoint. The deploy workflow ships a new deployment and shifts traffic gradually.

| | |
|---|---|
| Id | `online-bluegreen` |
| Network | public |
| Serving | online (blue/green) |
| Adds | Deploy workflow shifts 10% then 100% of traffic and retires the old deployment |
| IaC and CI/CD | Terraform or Bicep; GitHub or Azure DevOps |

The deploy workflow creates a new deployment, shifts 10% then 100% of traffic, and retires the old one.

## Use it

```powershell
New-MLOpsInputFile -Scenario online-bluegreen -Path inputs.yaml -Iac terraform -Cicd github
```

See the [cost estimates](_index.md#estimated-fixed-monthly-cost) and the [prerequisites](../prerequisites/_index.md).

## Microsoft documentation

- <https://learn.microsoft.com/azure/machine-learning/how-to-safely-rollout-online-endpoints>
