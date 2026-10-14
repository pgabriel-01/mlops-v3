# MLOps v3 Accelerator

A PowerShell module that turns one inputs file into a ready-to-run Azure Machine Learning MLOps repository: bootstrap, infrastructure (Terraform or Bicep on Azure Verified Modules), CI/CD (GitHub Actions or Azure DevOps) and a training workload.

| Phase | Page |
|---|---|
| 0. Planning | [Parameter checklist](parameter-checklist.md), [Data sources](data-sources.md), [Scenarios](scenarios/index.md) |
| 1. Prerequisites | [Prerequisites](prerequisites/index.md) |
| 2. Bootstrap | [Bootstrap](bootstrap.md) |
| 3. Run | [Run](run.md) |
| Customise | [Options](options/index.md) |
| Reference | [Gap analysis vs ALZ](alz-gap-analysis.md), [Azure Verified Modules](reference/azure-verified-modules.md) |

!!! warning "Status"
    Generated output is validated offline (render, `terraform validate`, `az bicep build`, pytest). It has not yet been applied to a live Azure subscription.
