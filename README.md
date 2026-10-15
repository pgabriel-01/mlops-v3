# MLOps v3 Accelerator for Azure Machine Learning

[![CI](https://github.com/pgabriel-01/mlops-v3/actions/workflows/ci.yml/badge.svg)](https://github.com/pgabriel-01/mlops-v3/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/pgabriel-01/mlops-v3?include_prereleases)](https://github.com/pgabriel-01/mlops-v3/releases)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/pgabriel-01/mlops-v3/badge)](https://scorecard.dev/viewer/?uri=github.com/pgabriel-01/mlops-v3)
[![Pull requests closed](https://img.shields.io/github/issues-pr-closed/pgabriel-01/mlops-v3)](https://github.com/pgabriel-01/mlops-v3/pulls?q=is%3Apr+is%3Aclosed)
[![Contributors](https://img.shields.io/github/contributors/pgabriel-01/mlops-v3)](https://github.com/pgabriel-01/mlops-v3/graphs/contributors)

## Introduction

This repository contains the PowerShell module and documentation for the MLOps v3 Accelerator. It turns one inputs file into a ready-to-run Azure Machine Learning MLOps repository: bootstrap (state, identity and repository wiring), infrastructure, CI/CD and a training workload. It is an opinionated implementation modeled on the [Azure Landing Zones (ALZ) Accelerator](https://github.com/Azure/ALZ-PowerShell-Module), with GitHub or Azure DevOps bootstrapping.

The module is a pre-release (`v0.2.0`). All 11 scenarios are applied, verified and destroyed live on Terraform and Bicep. The bootstrap apply, private runners and Azure DevOps are not yet verified live. See [Known issues](https://pgabriel-01.github.io/mlops-v3/known-issues/).

## Supported options

- **Infrastructure as code:** Terraform or Bicep, both built on Azure Verified Modules.
- **CI/CD:** GitHub Actions or Azure DevOps.
- **Scenarios:** 11 Azure ML scenarios, from a basic public workspace to GenAI and integration with an existing platform landing zone. Run `Get-MLOpsScenario` to list them, or see the [scenario guide](https://pgabriel-01.github.io/mlops-v3/scenarios/).
- **Data:** the bundled taxi CSV, or your own CSV in ADLS Gen2.

Please refer to the [documentation](https://pgabriel-01.github.io/mlops-v3/) for detailed features and usage instructions.

## Quick start

To get going right now, run these PowerShell steps:

```powershell
Import-Module ./src/MLOpsAccelerator/MLOpsAccelerator.psd1
Deploy-MLOpsAccelerator -InputFile "inputs.yaml" -OutputPath ./out -Deploy
```

No `inputs.yaml` yet? Create one with `New-MLOpsInputFile`, or run `Deploy-MLOpsAccelerator` on its own and answer the prompts. The module is not on the PowerShell Gallery yet ([issue 35](https://github.com/pgabriel-01/mlops-v3/issues/35)); each release attaches a zip on the [releases page](https://github.com/pgabriel-01/mlops-v3/releases).

## Software requirements

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

You can see the full requirements in the [prerequisites](https://pgabriel-01.github.io/mlops-v3/prerequisites/). To check them, run:

```powershell
Test-MLOpsAcceleratorRequirement
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [DEVELOPER.md](DEVELOPER.md). Report security issues through [SECURITY.md](SECURITY.md) and get help through [SUPPORT.md](SUPPORT.md).

## License

[MIT](LICENSE)
