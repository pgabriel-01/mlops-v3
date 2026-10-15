---
title: "Quick start"
weight: 50
---

## 1. Prerequisites

Install these tools, sign in with `az login`, and create a GitHub token or Azure DevOps PAT. See the [parameter checklist](planning/parameter-checklist.md) and [prerequisites](prerequisites/_index.md) for details.

| Tool | Version | Direct download |
|---|---|---|
| PowerShell | 7.4 or newer (tested on 7.4.6). Windows PowerShell 5.1 does not work. | [PowerShell 7.4.6 releases](https://github.com/PowerShell/PowerShell/releases/tag/v7.4.6) |
| `powershell-yaml` module | 0.4.7 or newer | [0.4.7 on the PowerShell Gallery](https://www.powershellgallery.com/packages/powershell-yaml/0.4.7), or `Install-PSResource powershell-yaml -Version 0.4.7` |
| Terraform | 1.16.0 or newer (tested on 1.16.5) | [Terraform 1.16.5 downloads](https://releases.hashicorp.com/terraform/1.16.5/) |
| Azure CLI | tested on 2.90.0; newer releases should work | [Windows installer](https://aka.ms/installazurecliwindows), [2.90.0 release](https://github.com/Azure/azure-cli/releases/tag/azure-cli-2.90.0) (macOS and Linux: [install steps](https://learn.microsoft.com/cli/azure/install-azure-cli)) |
| Bicep | current, only for `iac: bicep` | `az bicep install`, or the [Bicep releases](https://github.com/Azure/bicep/releases/latest) |
| git | current | [git downloads](https://git-scm.com/downloads) |
| GitHub CLI (`gh`) | optional, 2.x (tested on 2.102.0) | [GitHub CLI releases](https://github.com/cli/cli/releases/latest) |

The Azure ML CLI extension (`ml` 2.45.1) is installed by the generated pipelines, so you do not install it yourself. Python 3.14 and the package versions are pinned in `versions.lock.json` and are used only by the pipelines.

## 2. Bootstrap

```powershell
Import-Module ./src/MLOpsAccelerator/MLOpsAccelerator.psd1
Get-MLOpsScenario                                   # pick a scenario
New-MLOpsInputFile -Scenario managed-vnet-approved -Path inputs.yaml -Iac terraform -Cicd github
Test-MLOpsAcceleratorInput -InputFile inputs.yaml   # validate against the schema
Deploy-MLOpsAccelerator -InputFile inputs.yaml -OutputPath ./out            # generate only
Deploy-MLOpsAccelerator -InputFile inputs.yaml -OutputPath ./out -Deploy    # generate and bootstrap
```

## 3. Run

See [Run](run.md) for pushing the project, approvals, running each pipeline, local runs and cleanup.

## Keeping current

```powershell
Test-MLOpsAcceleratorVersion      # compare pins with latest releases
Update-MLOpsAcceleratorVersion
```

Terraform stays on `azurerm` 4.x because Azure Verified Modules require a version below 5.0; see `versions.lock.json`.

## Phases of the generated project

- Phase 0: platform prerequisites (outside the repository; private scenarios only).
- Phase 1: bootstrap (`terraform apply` in `bootstrap/`).
- Phase 2: infrastructure (`infra` pipeline, one environment at a time, with approvals).
- Phase 3: workload (`ml-train`).
- Phase 4: serve (`ml-deploy` and `ml-promote`).

The generated README has the full table with a stop-and-check step for each phase.
