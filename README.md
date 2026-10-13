# MLOps v3 Accelerator

A PowerShell module that turns one inputs file into a ready-to-run Azure Machine Learning MLOps repository: bootstrap (state, identity, repo wiring), infrastructure, CI/CD and a tabular training workload. Modeled on the ALZ Accelerator.

| Choice | Options |
|---|---|
| IaC | Terraform, Bicep |
| CI/CD | GitHub Actions, Azure DevOps |
| Scenario | 11 AML scenarios (see below) |
| Data | bundled taxi CSV, or your own CSV in ADLS Gen2 (`data_source: adls`) |

## How it works (phases)

| Phase | What you do | Details |
|---|---|---|
| 0. Prerequisites | Install PowerShell 7.4+, `powershell-yaml`, `az` (logged in), Terraform; set `GITHUB_TOKEN` or `AZDO_PERSONAL_ACCESS_TOKEN` | [parameter-checklist.md](docs/parameter-checklist.md) |
| 1. Plan | Pick a scenario, IaC, CI/CD and data source | [scenarios.md](docs/scenarios.md), [data-sources.md](docs/data-sources.md) |
| 2. Configure | Generate an inputs file and edit it | `New-MLOpsInputFile` |
| 3. Generate / bootstrap | Render the repo; with `-Deploy`, create state, identities and repo wiring | `Deploy-MLOpsAccelerator` |
| 4. Run | Push the generated repo and run the CI/CD pipelines (infra, train, deploy) | [getting-started.md](docs/getting-started.md) |
| 5. Maintain | Check and bump pins | `Test-MLOpsAcceleratorVersion`, `Update-MLOpsAcceleratorVersion` |

## Quick start
```powershell
Install-PSResource powershell-yaml
Import-Module ./src/MLOpsAccelerator/MLOpsAccelerator.psd1
Get-MLOpsScenario
New-MLOpsInputFile -Scenario basic-public -Path my-inputs.yaml   # edit
Deploy-MLOpsAccelerator -InputFile my-inputs.yaml -OutputPath ./my-mlops          # generate
Deploy-MLOpsAccelerator -InputFile my-inputs.yaml -OutputPath ./my-mlops -Deploy  # generate + bootstrap
```
For `-Deploy` you need `az` (logged in), `terraform`, plus `GITHUB_TOKEN` or `AZDO_PERSONAL_ACCESS_TOKEN`.

## Commands
| Command | Purpose |
|---|---|
| `Test-MLOpsAcceleratorRequirement` | Pre-flight check (tools, `az login`, tokens, network); also runs before `-Deploy` |
| `New-MLOpsInputFile` / `Deploy-MLOpsAccelerator -Interactive` | Write the inputs file, optionally via prompts |
| `Deploy-MLOpsAccelerator` | Generate; `-Deploy` plans, asks for approval, applies (`-AutoApprove` to skip); `-Upgrade` regenerates an existing project; `-Destroy` tears down the bootstrap |
| `Remove-MLOpsAccelerator` | Destroy the bootstrap and optionally delete the local folder |
| `Grant-MLOpsStorageAccess` | Give the AML workspace identity Storage Blob Data Reader for `data_source: adls` |
| `Test-/Update-MLOpsAcceleratorVersion` | Check and bump pins |

## Versions
`versions.lock.json` is the single source of truth. Python is pinned to **3.14**, not 3.15: 3.15 is still a release candidate and `pyarrow` has no wheels for it. The whole stack was checked with `pip check` on 3.14 and the training pipeline run end to end. Bump `python` in the lock once 3.15 wheels exist. `azureml-featurestore` supports only Python <= 3.12 (relevant to the planned Phase 2, which runs on Spark).

## Design notes / best-practice mapping
- Security (WAF/CAF): OIDC/workload identity federation, no secrets; Key Vault with RBAC and purge protection; Terraform state in Azure Storage with Entra auth; checkov in CI; per-environment approvals through GitHub environments / ADO environments.
- Operations: Log Analytics + App Insights; dev -> prod promotion, one state file per environment.
- MLOps: pipeline (prep, train, evaluate, register), model registry, managed online endpoint with safe rollout.

## Scenarios

Eleven AML scenarios (public, managed VNet, BYO VNet, batch, blue/green, feature store, registry, governance, GenAI, existing platform) are described in [docs/scenarios.md](docs/scenarios.md); the input checklist is in [docs/parameter-checklist.md](docs/parameter-checklist.md).

```powershell
Get-MLOpsScenario
New-MLOpsInputFile -Scenario managed-vnet-approved -Path inputs.yaml -Iac bicep -Cicd github
Deploy-MLOpsAccelerator -InputFile inputs.yaml -OutputPath ./out
```

## Azure Verified Modules

Infra and bootstrap use AVM resource modules (Terraform registry `Azure/avm-res-*`, Bicep `br/public:avm/res/*`) and utility modules (`avm-utl-regions`, `Azure/naming`). No AVM pattern module fits a plain Azure ML workspace (existing ones target Foundry/landing zones/azd), so none is used. Terraform is held on azurerm 4.x because AVM modules require `< 5.0`; the version checker honours this via `holds` in `versions.lock.json`. AVM telemetry is on by default; set `enable_telemetry = false` to disable.

## Known limitations
- Bootstrap is always Terraform (like ALZ), even when IaC is Bicep.
- Deploy identity gets Contributor + RBAC Administrator at subscription scope; scope it down for production.
- Not verified against a live Azure subscription: bootstrap apply, AML runtime with Python 3.14 conda image, endpoint deployment.
- Phase 2 (Parquet transactions data + managed feature store) is not implemented beyond an optional feature store resource.

## Develop
`Invoke-Pester ./tests`. Rendered output is additionally validated with `terraform validate`, `az bicep build` and the generated pytest (see `.github/workflows/ci.yml`).
