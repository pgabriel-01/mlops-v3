---
title: "What's new"
weight: 2
---

Newest first. The first release is `v0.1.0` (2026-10-14); entries older than that are listed by date. Releases will be tagged `v0.x.y` until the first gold release (`v1.0.0`), which requires all 11 scenarios to be verified live. Entries are tagged **[Important]** when you must act, or **[Preview]** for features that are not applied to a live subscription yet.

{{% callout style="warning" title="Partly applied to live Azure" %}}
All generated output is validated offline (render, `terraform validate`, `az bicep build`, pytest). All 11 scenarios are also verified live for Terraform and Bicep by the `e2e` workflow; see [Known issues](known-issues.md#live-deployment-coverage).
{{% /callout %}}

## Unreleased

### Added

- `e2e` workflow: a final job removes any leftover test resource groups and writes a pass or fail summary. Runs are manual and need a scenario list; the weekly schedule was removed, and Bicep deployments are named per scenario so parallel jobs no longer collide.

## v0.2.0 (2026-10-15)

All 11 scenarios are now verified live on Terraform and Bicep. The bootstrap, private runners and Azure DevOps are still not applied live.

### Fixed

- Terraform and Bicep, feature store: sets `featureStoreSettings`, passes the dependent storage, Key Vault and Application Insights resources, enables the managed network that serverless Spark needs, and drops the container registry because a managed network requires a Premium one.
- Terraform, governance: the storage account diagnostic setting now sends the `Transaction` metric, so Azure creates it and the apply no longer times out.
- `e2e` workflow: removes resource locks before deleting the resource group, so the governance scenario can be destroyed.

### Verified

- Scenarios 6 to 11 applied, verified and destroyed live on Terraform and Bicep.
- `e2e` workflow: scenario 11 runs against a stand-in platform (VNet, Log Analytics and private DNS zones) that the job creates and removes.

## v0.1.0 (2026-10-14)

First tagged pre-release. Scenarios 1 to 5 are verified live on Terraform and Bicep; scenarios 6 to 11 are validated offline and by plan or what-if only.

### Fixed

- Terraform: `workspace_managed_network` is now one object with conditional fields, fixing "Inconsistent conditional result types" on managed-network scenarios.
- Bicep: public scenarios set explicit `Allow` network ACLs on storage, Key Vault and the container registry.
- `e2e` workflow: re-logs in before verify and destroy because the OIDC token expires after about 5 minutes.

### Fixed (Terraform, byo-vnet)

- Private DNS zone counts are known at plan time, storage blob and file private endpoints have unique names, and the workspace, hub and compute cluster use `depends_on` so private endpoints exist first.

### Verified

- Scenarios 1 to 5 applied, verified and destroyed live on Terraform and Bicep.

## 2026-10-13

### Added

- `data_source: taxi-parquet`, and the bundled samples (`taxi-csv`, `taxi-parquet`) are now registered as **MLTable** data assets (`type: mltable`, mounted read-only into the prep step). The Parquet sample is a 2,000-row slice with the same columns. The Azure Open Datasets green-taxi Parquet has a different schema (and 2 GB, East US only), so it is not bundled. `prep.py` reads the MLTable file itself because the `mltable` package requires Python below 3.14. `adls` stays a single-file `uri_file`.

- The module is packaged for PowerShell Gallery: `scripts/Build-Module.ps1` stages a self-contained module (templates, schema and version lock bundled), and a `v*` tag builds it, attaches a zip to the GitHub release and publishes to the Gallery when the `PSGALLERY_API_KEY` secret is set. Until the first publish, install with `install-local.ps1`.

- The interactive prompt now mirrors ALZ: numbered menus for scenario, IaC, CI/CD, region and subscription, `[0]` for manual entry, a "(current)" default marker, `[AZ]` on zone-enabled regions (from `az account list-locations`, limited to regions where Azure ML workspaces are available), subscriptions from the current tenant, and a warning when the chosen region has no zones. Without `az` it falls back to free text.

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
