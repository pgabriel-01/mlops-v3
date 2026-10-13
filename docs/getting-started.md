# Getting started

## 1. Prerequisites

See the [parameter checklist](parameter-checklist.md). In short: PowerShell 7.4+, `powershell-yaml`, Terraform, Azure CLI
(plus Bicep for `iac: bicep`), `az login`, and a GitHub token or Azure DevOps PAT.

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

Push `./out` to the repository, merge to `main` to deploy `infra/`, then run `ml-train` and `ml-deploy`
(`ml-promote` for the registry scenario).

## Keeping current

```powershell
Test-MLOpsAcceleratorVersion      # compare pins with latest releases
Update-MLOpsAcceleratorVersion
```

Terraform stays on azurerm 4.x because Azure Verified Modules require `< 5.0`; see `versions.lock.json`.
