---
title: "Phase 2 - Bootstrap"
weight: 30
---

Generates your project and, for the Terraform bootstrap, creates the version control repository, Azure identity and state storage.

## 1. Install the module (local, until it is published)

```powershell
git clone <this repo> ; cd mlops-v3
./install-local.ps1          # copies the module and templates to your user module path
# ./install-local.ps1 -Uninstall
```

Requires PowerShell 7.4 or newer and `Install-PSResource` (in-box from PowerShell 7.4). The other tools you need (Terraform, Azure CLI, git and so on) are listed with install links in [prerequisites](prerequisites/_index.md). Re-run after `git pull` to update.

## 2. Create the inputs

```powershell
Deploy-MLOpsAccelerator -Interactive        # wizard writes inputs.yaml
# or
New-MLOpsInputFile -Scenario 1 -Path inputs.yaml
```

Review `inputs.yaml` (subscription, region, environments, networking address spaces) before continuing.

## 3. Sign in to Azure

```powershell
az login --tenant "<tenant-id>" --use-device-code
az account set --subscription "<bootstrap-subscription-id>"
```

## 4. Run

```powershell
Deploy-MLOpsAccelerator -InputFile inputs.yaml -OutputPath ./my-mlops
```

The requirements check runs first, then the Terraform plan; type `yes` to apply (`-AutoApprove` skips the prompt).

{{% callout style="note" %}}
The module is pre-release (v0.2.0) and is not on the PowerShell Gallery yet; publishing is deferred ([issue 35](https://github.com/pgabriel-01/mlops-v3/issues/35)); each tagged release attaches a zip on the GitHub releases page. Until then use `install-local.ps1`, or import `src/MLOpsAccelerator/MLOpsAccelerator.psd1` directly.
{{% /callout %}}

Next, follow the generated project's README (phases 2 to 4), or continue with [Phase 3 - Run](run.md).
