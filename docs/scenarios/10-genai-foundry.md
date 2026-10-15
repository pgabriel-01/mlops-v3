---
title: "10 - GenAI: AI Foundry hub and project"
weight: 10
---

Hub workspace, AI Services account and a project for prompt flow and GenAIOps.

| | |
|---|---|
| Id | `genai-foundry` |
| Network | public |
| Serving | none |
| Adds | AI Foundry hub, AI Services account and project |
| IaC and CI/CD | Terraform or Bicep; GitHub or Azure DevOps |

Provisions an AI Foundry hub, an AI Services account and a project. The sample training workload is not used for GenAI; this scenario is platform only.

## Use it

```powershell
New-MLOpsInputFile -Scenario genai-foundry -Path inputs.yaml -Iac terraform -Cicd github
```

See the [cost estimates](_index.md#estimated-fixed-monthly-cost) and the [prerequisites](../prerequisites/_index.md).

## Microsoft documentation

- <https://learn.microsoft.com/azure/ai-foundry/concepts/architecture>
