# MLOps v3 Accelerator

[![CI](https://github.com/pgabriel-01/mlops-v3/actions/workflows/ci.yml/badge.svg)](https://github.com/pgabriel-01/mlops-v3/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A PowerShell module that turns one inputs file into a ready-to-run Azure Machine Learning MLOps repository: bootstrap (state, identity and repository wiring), infrastructure, CI/CD and a tabular training workload. It is modeled on the [Azure Landing Zones (ALZ) Accelerator](https://github.com/Azure/ALZ-PowerShell-Module).

**Status:** pre-release (`v0.2.0`). All 11 scenarios are applied, verified and destroyed live on Terraform and Bicep. The bootstrap apply, private runners and Azure DevOps are not yet verified live; see [Known issues](https://pgabriel-01.github.io/mlops-v3/known-issues/).

| Choice | Options |
|---|---|
| Infrastructure as code | Terraform or Bicep, both on Azure Verified Modules |
| CI/CD | GitHub Actions or Azure DevOps |
| Scenario | 11 Azure ML scenarios (see [Scenarios](#scenarios)) |
| Data | Bundled taxi CSV, or your own CSV in ADLS Gen2 (`data_source: adls`) |

## Required tools

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

Full details are in the [prerequisites](https://pgabriel-01.github.io/mlops-v3/prerequisites/).

## Quick start

```powershell
Import-Module ./src/MLOpsAccelerator/MLOpsAccelerator.psd1   # or ./install-local.ps1
Test-MLOpsAcceleratorRequirement                              # checks tools, sign-in and tokens
New-MLOpsInputFile -Scenario managed-vnet-approved -Path inputs.yaml -Iac terraform -Cicd github
Deploy-MLOpsAccelerator -InputFile inputs.yaml -OutputPath ./out            # generate only
Deploy-MLOpsAccelerator -InputFile inputs.yaml -OutputPath ./out -Deploy    # generate and bootstrap
```

Run `Deploy-MLOpsAccelerator` with no arguments to answer prompts instead; it writes the inputs file for you. For `-Deploy` you need `az login`, Terraform, and either `GITHUB_TOKEN` or `AZDO_PERSONAL_ACCESS_TOKEN`. The module is not yet on the PowerShell Gallery ([issue 35](https://github.com/pgabriel-01/mlops-v3/issues/35)); each release attaches a zip on the [releases page](https://github.com/pgabriel-01/mlops-v3/releases).

## How it works

| Phase | What you do | Docs |
|---|---|---|
| 0. Plan | Pick a scenario, IaC, CI/CD and data source | [Planning](https://pgabriel-01.github.io/mlops-v3/planning/), [Scenarios](https://pgabriel-01.github.io/mlops-v3/scenarios/), [Parameter checklist](https://pgabriel-01.github.io/mlops-v3/planning/parameter-checklist/) |
| 1. Prerequisites | Install the tools, sign in to Azure, create a token | [Prerequisites](https://pgabriel-01.github.io/mlops-v3/prerequisites/) |
| 2. Bootstrap | Generate the inputs file, then render and bootstrap | [Bootstrap](https://pgabriel-01.github.io/mlops-v3/bootstrap/) |
| 3. Run | Push the generated repository and run the pipelines (infra, train, deploy) | [Run](https://pgabriel-01.github.io/mlops-v3/run/) |
| 4. Maintain | Check and update pinned versions, upgrade a generated project | [Upgrade guide](https://pgabriel-01.github.io/mlops-v3/upgrade-guide/) |

## Scenarios

| Id | Scenario |
|---|---|
| 1 | Basic, public endpoints |
| 2 | Secure: managed VNet, internet outbound |
| 3 | Secure: managed VNet, approved outbound only |
| 4 | Secure: bring-your-own VNet |
| 5 | Batch training and batch inference |
| 6 | Online endpoint with blue/green rollout |
| 7 | Managed feature store |
| 8 | Multi-environment with shared registry |
| 9 | Monitoring and governance |
| 10 | GenAI: AI Foundry hub and project |
| 11 | Integrate with an existing platform landing zone |

Run `Get-MLOpsScenario` to list them with their ids. Details and cost estimates are in the [scenario guide](https://pgabriel-01.github.io/mlops-v3/scenarios/).

## Commands

| Command | Purpose |
|---|---|
| `Test-MLOpsAcceleratorRequirement` | Pre-flight check of tools, `az login`, tokens and network; also runs before `-Deploy` |
| `Get-MLOpsScenario` | List the scenarios |
| `New-MLOpsInputFile` | Write an inputs file for a scenario |
| `Test-MLOpsAcceleratorInput` | Validate an inputs file against the schema |
| `Deploy-MLOpsAccelerator` | Generate the project. `-Deploy` plans, asks for approval and applies (`-AutoApprove` skips the prompt). `-Upgrade` regenerates an existing project. `-Destroy` tears down the bootstrap. |
| `Remove-MLOpsAccelerator` | Destroy the bootstrap and optionally delete the local folder |
| `Grant-MLOpsStorageAccess` | Give the workspace identity Storage Blob Data Reader for `data_source: adls` |
| `Test-MLOpsAcceleratorVersion` and `Update-MLOpsAcceleratorVersion` | Check and update the pinned versions |

## Design

- **Security:** OIDC and workload identity federation with no stored secrets, Key Vault with RBAC and purge protection, Terraform state in Azure Storage with Entra authentication, checkov in CI, and per-environment approvals.
- **Operations:** Log Analytics and Application Insights, promotion from `dev` to `test` to `prod`, and one state file per environment.
- **MLOps:** a training pipeline (prepare, train, evaluate, register), a model registry and a managed online endpoint with safe rollout.
- **Azure Verified Modules:** infrastructure and bootstrap use AVM resource and utility modules. No AVM pattern module fits a plain Azure ML workspace, so none is used. Terraform stays on azurerm 4.x because the AVM modules require `< 5.0`. AVM telemetry is on by default; set `enable_telemetry = false` to turn it off.
- **Versions:** `versions.lock.json` is the single source of truth. Python is pinned to 3.14 because 3.15 is still a release candidate and `pyarrow` has no wheels for it.

## Known limitations

- The bootstrap is always Terraform, like ALZ, even when the workload IaC is Bicep.
- The deploy identity gets Contributor and RBAC Administrator at subscription scope. Scope it down for production.
- Not yet verified live: the bootstrap apply, private runners, Azure DevOps, endpoint deployment, and the `rai` option.

The full list is in [Known issues](https://pgabriel-01.github.io/mlops-v3/known-issues/).

## Documentation

The docs live in `docs/` and are published at <https://pgabriel-01.github.io/mlops-v3/>. Preview them with `hugo server --source site`; build with `hugo --source site --minify`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [DEVELOPER.md](DEVELOPER.md). Report security issues through [SECURITY.md](SECURITY.md); get help through [SUPPORT.md](SUPPORT.md).

## License

[MIT](LICENSE)
