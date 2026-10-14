# Phase 1 - Prerequisites

Work through the three steps, then continue to [Plan and configure](../getting-started.md). Run `Test-MLOpsAcceleratorRequirement` at any point to check the tools, sign-ins and tokens below.

## 1 - Tools and internet access

Install these and make sure they are on the PATH of a PowerShell 7 (`pwsh`) terminal:

| Tool | Version | Needed for |
|---|---|---|
| PowerShell | 7.4+ | the module |
| `powershell-yaml` module | 0.4.7+ | reading inputs (`Install-PSResource powershell-yaml`) |
| Terraform | 1.16.x (tested pin in `versions.lock.json`) | the bootstrap, always (and infra when `iac: terraform`) |
| Azure CLI | current | sign-in, `az bicep`, ML CLI used by the pipelines |
| Bicep (`az bicep install`) | current | only when `iac: bicep` |
| git | current | pushing the generated repository |
| GitHub CLI (`gh`) | optional | supplies the GitHub token |

Internet access is needed to download Terraform providers and AVM modules (`registry.terraform.io`, `mcr.microsoft.com` for Bicep AVM), reach Azure, and reach GitHub or Azure DevOps. If you must use mirrors, configure Terraform provider mirrors yourself; this has not been tested.

Not supported or not tested:

- Running behind a corporate proxy. Use a temporary Azure VM instead.
- Azure Cloud Shell.
- Development and local testing so far were on macOS. CI runs the tests and render/validate steps on Ubuntu, Windows and macOS runners; Windows has not been exercised by hand.
- Windows: use PowerShell 7 (not Windows PowerShell 5.1), enable long paths (`git config --system core.longpaths true` and the `LongPathsEnabled` registry setting) and keep `-OutputPath` short, because Terraform and Bicep module caches create deep folders.

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
- [ ] For private scenarios (4, 11, and managed VNet): a self-hosted agent that can reach the private endpoints
- [ ] `Test-MLOpsAcceleratorRequirement` shows no required failures
