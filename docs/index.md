# MLOps v3 Accelerator

A PowerShell module that turns one inputs file into a ready-to-run Azure Machine Learning MLOps repository: bootstrap, infrastructure (Terraform or Bicep on Azure Verified Modules), CI/CD (GitHub Actions or Azure DevOps) and a training workload.

| Phase | Page |
|---|---|
| 0. Prerequisites | [Prerequisites](prerequisites/index.md), [Parameter checklist](parameter-checklist.md) |
| 1. Plan | [Scenarios](scenarios.md), [Data sources](data-sources.md) |
| 2-4. Configure, generate, run | [Getting started](getting-started.md) |
| Reference | [Gap analysis vs ALZ](alz-gap-analysis.md) |

!!! warning "Status"
    Generated output is validated offline (render, `terraform validate`, `az bicep build`, pytest). It has not yet been applied to a live Azure subscription.
