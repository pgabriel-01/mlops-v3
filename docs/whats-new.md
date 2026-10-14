---
title: "What's new"
weight: 2
---

Newest first. The accelerator has not had a tagged release yet, so everything is listed under a dated section. Entries are tagged **[Important]** when you must act, or **[Preview]** for features that are not applied to a live subscription yet.

{{% callout style="warning" title="Not yet applied to live Azure" %}}
All generated output is validated offline (render, `terraform validate`, `az bicep build`, pytest). `tests/Invoke-E2E.ps1` has not been run against a subscription. Only scenario 1 (Terraform) has been deployed by hand; see [Known issues](known-issues.md).
{{% /callout %}}
## 2026-10-13

### Added

- The interactive prompt lists the regions in your subscription with their availability zone count, accepts only listed regions, and warns when the chosen region has no zones. Without `az` it falls back to free text.

- **[Preview]** `policy_mode: audit | deny | none`: built-in Azure Policy guardrails on every environment resource group, documented under [Azure Policy](policy/_index.md). **[Important]** the bootstrap now grants the deploy identity *Resource Policy Contributor*; re-run the bootstrap for existing projects. The generated compute cluster now disables local authentication.
- 11 AML scenarios on Terraform and Bicep, built on Azure Verified Modules: [Scenarios](scenarios/_index.md).
- One page per [scenario](scenarios/_index.md) and per [option](options/_index.md).
- Estimated fixed monthly cost per scenario, from the Azure Retail Prices API (`scripts/Get-ScenarioCostEstimates.ps1`).
- `data_source: adls`: read your own CSV from ADLS Gen2 with an identity-based datastore. **[Important]** the workspace identity needs *Storage Blob Data Reader*; see [Data sources](planning/data-sources.md).
- [Phase 0 Planning](planning/_index.md) decisions that map to `inputs.yaml`.
- [Phase 1 Prerequisites](prerequisites/_index.md), with a resource provider check in `Test-MLOpsAcceleratorRequirement`.
- [Phase 2 Bootstrap](bootstrap.md) and [Phase 3 Run](run.md) guides.
- Plan and approve before apply, `Remove-MLOpsAccelerator`, `-Upgrade`, `-Interactive` and `Grant-MLOpsStorageAccess`.
- `install-local.ps1` for local install and uninstall, since the module is not published yet.
- Default environments are `dev`, `test` and `prod`.
- Pipelines are numbered by phase.

### Changed

- **[Important]** Docs renumbered: Planning 0, Prerequisites 1, Bootstrap 2, Run 3.
- Python is pinned to 3.14. Held back on purpose: `azurerm` below 5.0 (AVM requirement), `pyarrow` below 26 (mlflow cap) and `azureml-mlflow` 1.60.0.
- Generated files are LF-only on every OS.
- CI runs on Ubuntu, Windows and macOS (not yet run; needs a push).

### Fixed

- Python lookup in `Update-MLOpsAcceleratorVersion` now works on Windows (`python`, `python3`, `python3.14`).
- The scenario test matrix uses the OS temp folder instead of `$env:TMPDIR`.

### Known gaps

- Compute sizes are not inputs yet.
- The bootstrap sets no approval reviewers and does not register Azure DevOps pipelines.
- No Parquet data source or managed feature store pack yet.
- Not published to the PowerShell Gallery.

See [Gap analysis vs ALZ](reference/alz-gap-analysis.md) for the full comparison.
