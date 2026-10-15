---
title: "Phase 1 - Prerequisites"
weight: 20
---

Work through the three steps, then continue to [Quick start](../getting-started.md). Run `Test-MLOpsAcceleratorRequirement` at any point to check the tools, sign-ins and tokens below.

## 1 - Tools and internet access

Install these and make sure they are on the PATH of a PowerShell 7.4 or newer (`pwsh`) terminal:

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

Internet access is needed to download Terraform providers and AVM modules (`registry.terraform.io`, `mcr.microsoft.com` for Bicep AVM), reach Azure, and reach GitHub or Azure DevOps. If you must use mirrors, configure Terraform provider mirrors yourself; this has not been tested.

Not supported or not tested:

- Running behind a corporate proxy. Use a temporary Azure VM instead.
- Azure Cloud Shell.
- Development and local testing so far were on macOS. CI runs the tests and render and validate steps on Ubuntu, Windows and macOS runners; Windows has not been exercised by hand.
- Windows: use PowerShell 7.4 or newer (not Windows PowerShell 5.1), enable long paths (`git config --system core.longpaths true` and the `LongPathsEnabled` registry setting) and keep `-OutputPath` short, because Terraform and Bicep module caches create deep folders.

## 2 - Azure subscriptions and permissions

See [Azure subscriptions and permissions](azure.md).

## 3 - Version control system

Choose one and follow its page:

- [GitHub](github.md)
- [Azure DevOps](azure-devops.md)

You also need an empty local folder for the generated output (`-OutputPath`).

## Checklist

- [ ] Tools installed and on the PATH
- [ ] Internet access to the registries above
- [ ] Azure subscription ready, resource providers registered, permissions granted
- [ ] Token created for GitHub or Azure DevOps
- [ ] Compute quota available in the region (and AI Foundry quota for scenario 10)
- [ ] For private scenarios (2 to 4 and 11): a self-hosted agent that can reach the private endpoints
- [ ] `Test-MLOpsAcceleratorRequirement` shows no required failures
