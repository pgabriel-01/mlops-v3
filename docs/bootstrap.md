---
title: "Phase 2 - Bootstrap"
weight: 30
---

Generates your project and, for Terraform bootstrap, creates the version-control repo, Azure identity and state storage.

## 1. Install the module (local, until it is published)

```powershell
git clone <this repo> ; cd mlops-v3
./install-local.ps1          # copies the module + templates to your user module path
# ./install-local.ps1 -Uninstall
```

Requires PowerShell 7 and `Install-PSResource` (in-box from PowerShell 7.4). Re-run after `git pull` to update.

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
Publishing to the PowerShell Gallery is deferred. Until then use `install-local.ps1`, or import `src/MLOpsAccelerator/MLOpsAccelerator.psd1` directly.
{{% /callout %}}
Next: the generated project's README (Phases 2-4).
