---
title: "5 - Batch training and batch inference"
weight: 5
---

# 5 - Batch training and batch inference

Compute cluster plus a batch endpoint and deployment with a scheduled scoring job.

| | |
|---|---|
| Id | `batch-scoring` |
| Network | public |
| Serving | batch |
| Adds | Batch endpoint and deployment, nightly scoring workflow |
| IaC / CI/CD | Terraform or Bicep; GitHub or Azure DevOps |

Scoring runs as a scheduled batch job (nightly workflow) instead of a real-time endpoint.

## Use it

```powershell
New-MLOpsInputFile -Scenario batch-scoring -Path inputs.yaml -Iac terraform -Cicd github
```

See the [cost estimates](index.md#estimated-fixed-monthly-cost) and the [prerequisites](../prerequisites/index.md).

## Microsoft documentation

- <https://learn.microsoft.com/azure/machine-learning/concept-endpoints-batch>
