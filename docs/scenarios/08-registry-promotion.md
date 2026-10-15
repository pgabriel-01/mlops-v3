---
title: "8 - Multi-environment with shared registry"
weight: 8
---

An AML registry shared across environments; models are registered in `dev` and promoted to `test` and `prod`.

| | |
|---|---|
| Id | `registry-promotion` |
| Network | public |
| Serving | online |
| Adds | Shared AML registry in the first environment, `ml-promote` workflow, deploy from the registry |
| IaC / CI/CD | Terraform or Bicep; GitHub or Azure DevOps |

A shared AML registry is created in the first environment. `ml-promote` copies the model through it and deployments pull from the registry.

## Use it

```powershell
New-MLOpsInputFile -Scenario registry-promotion -Path inputs.yaml -Iac terraform -Cicd github
```

See the [cost estimates](_index.md#estimated-fixed-monthly-cost) and the [prerequisites](../prerequisites/_index.md).

## Microsoft documentation

- <https://learn.microsoft.com/azure/machine-learning/how-to-share-models-pipelines-across-workspaces-with-registries>
