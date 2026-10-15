---
title: "What's new"
weight: 2
---

Newest first. The latest release is `v0.2.0` (2026-10-15); the first was `v0.1.0` (2026-10-14). Releases are tagged `v0.x.y` until the first gold release (`v1.0.0`), which also needs the bootstrap, private runners and Azure DevOps verified live. The module is pre-release and is not on the PowerShell Gallery yet. Entries are tagged **[Important]** when you must act, or **[Preview]** for features that are not applied to a live subscription yet.

{{% callout style="warning" title="Workload applied live, bootstrap not yet" %}}
All generated output is validated offline (render, `terraform validate`, `az bicep build`, pytest). Scenarios 1 to 11 are also verified live for Terraform and Bicep by the `e2e.yml` workflow; scenario 12 is not yet. The bootstrap apply, private runners and private state storage, Azure DevOps, separate plan and apply identities, Managed DevOps Pools, the `rai` option, the scenario 7 feature-set pack and endpoint deployment are not verified live; see [Known issues](known-issues.md#live-deployment-coverage).
{{% /callout %}}

## Unreleased

### Changed

- The `workload` input is renamed `workload_type` to stop it being confused with `workloads`. The old name is still accepted and prints a deprecation warning. Workload names that clash with generated folders (`src`, `data`, `tests`, `mlops`, `infra`, `bootstrap`, `docs`, `rag`, `workloads`) are now rejected.
- The bundled taxi samples now come from the MIT-licensed `azureml-examples` repository, with the license in `data/NOTICE.md`. The schema and data source docs now agree that `taxi-parquet` is supported.

- Resource name suffix is now exactly 5 characters (was 4, with the schema allowing 4 to 6 while Bicep required 4). The generated default is 5 characters and `name_suffix` must be 5 lowercase letters or digits. Regenerating an existing project changes its derived resource names, so set a stable `name_suffix` only on new deployments and plan to redeploy preview environments.
- Input validation is stricter: properties that do not apply to the scenario are rejected, `use_private_networking` is rejected with Azure DevOps, private networking requires a self-hosted `runner_label`, environments are sorted into dev, test, prod order, registry scenarios need two environments, and CIDR ranges are checked for private space, host bits, size and overlap.

### Added

- A [CSV or parquet](options/13-csv-or-parquet.md) options page that explains why parquet is worth learning and how to convert a CSV.
- **[Preview]** Scenario 12, `rag-llmops`: Azure AI Search, a chat and an embedding model deployment, an index of sample documents, and an evaluation step with a groundedness quality gate in the pipeline, on Terraform and Bicep. The new `rag` input section sets the models, capacity, search tier and gate threshold. The new `Test-MLOpsModelQuota` function, which `-Deploy` also runs, checks regional model and search quota first. Not yet applied live.
- `rag.search_location` input to place Azure AI Search in a different region than the rest of the workload, for when the main region is out of Search capacity. The quota check now reads Search usage for that region and warns that quota does not guarantee capacity.
- `e2e.yml` workflow: the identity needs a lock-management role for governance, and a final job removes any leftover test resource groups and writes a pass or fail summary. Runs are manual and need a scenario list; the weekly schedule was removed, and Bicep deployments are named per scenario so parallel jobs no longer collide.

## v0.2.0 (2026-10-15)

All 11 scenarios are now verified live on Terraform and Bicep. The bootstrap, private runners and Azure DevOps are still not applied live.

### Fixed

- Terraform and Bicep, feature store: sets `featureStoreSettings`, passes the dependent storage, Key Vault and Application Insights resources, enables the managed network that serverless Spark needs, and drops the container registry because a managed network requires a Premium one.
- Terraform, governance: the storage account diagnostic setting now sends the `Transaction` metric, so Azure creates it and the apply no longer times out.
- `e2e.yml` workflow: removes resource locks before deleting the resource group, so the governance scenario can be destroyed.

### Verified

- Scenarios 6 to 11 applied, verified and destroyed live on Terraform and Bicep.
- `e2e.yml` workflow: scenario 11 runs against a stand-in platform (VNet, Log Analytics and private DNS zones) that the job creates and removes.

## v0.1.0 (2026-10-14)

First tagged pre-release. Scenarios 1 to 5 are verified live on Terraform and Bicep; scenarios 6 to 11 are validated offline and by plan or what-if only.

### Fixed

- Terraform: `workspace_managed_network` is now one object with conditional fields, fixing "Inconsistent conditional result types" on managed-network scenarios.
- Bicep: public scenarios set explicit `Allow` network ACLs on storage, Key Vault and the container registry.
- `e2e.yml` workflow: re-logs in before verify and destroy because the OIDC token expires after about 5 minutes.

### Fixed (Terraform, byo-vnet)

- Private DNS zone counts are known at plan time, storage blob and file private endpoints have unique names, and the workspace, hub and compute cluster use `depends_on` so private endpoints exist first.

### Verified

- Scenarios 1 to 5 applied, verified and destroyed live on Terraform and Bicep.

## 2026-10-13

### Added

- `data_source: taxi-parquet`, and the bundled samples (`taxi-csv`, `taxi-parquet`) are now registered as **MLTable** data assets (`type: mltable`, mounted read-only into the prep step). The Parquet sample is a 2,000-row slice with the same columns. The Azure Open Datasets green-taxi Parquet has a different schema (2 GB, East US only), so it is not bundled. `prep.py` reads the MLTable file itself because the `mltable` package requires Python below 3.14. `adls` stays a single-file `uri_file`.

- The module is packaged for the PowerShell Gallery: `scripts/Build-Module.ps1` stages a self-contained module (templates, schema and version lock bundled), and a `v*` tag builds it, attaches a zip to the GitHub release and publishes to the Gallery when the `PSGALLERY_API_KEY` secret is set. The module is not published yet, so install with `install-local.ps1`.

- The interactive prompt now mirrors ALZ: numbered menus for scenario, IaC, CI/CD, region and subscription, `[0]` for manual entry, a `(current)` default marker, `[AZ]` on zone-enabled regions (from `az account list-locations`, limited to regions where Azure ML workspaces are available), subscriptions from the current tenant, and a warning when the chosen region has no zones. Without `az` it falls back to free text.

- **[Preview]** `policy_mode` (`audit`, `deny` or `none`): built-in Azure Policy guardrails on every environment resource group, documented under [Azure Policy](policy/_index.md). **[Important]** the bootstrap now grants the deploy identity *Resource Policy Contributor*; re-run the bootstrap for existing projects. The generated compute cluster now disables local authentication.
- 11 AML scenarios (now 12) on Terraform and Bicep, built on Azure Verified Modules: [Scenarios](scenarios/_index.md).
- One page per [scenario](scenarios/_index.md) and per [option](options/_index.md).
- Estimated fixed monthly cost per scenario, from the Azure Retail Prices API (`scripts/Get-ScenarioCostEstimates.ps1`).
- `data_source: adls`: read your own CSV from ADLS Gen2 with an identity-based datastore. **[Important]** the workspace identity needs *Storage Blob Data Reader*; see [Data sources](planning/data-sources.md).
- [Phase 0 - Planning](planning/_index.md) decisions that map to `inputs.yaml`.
- [Phase 1 - Prerequisites](prerequisites/_index.md), with a resource provider check in `Test-MLOpsAcceleratorRequirement`.
- [Phase 2 - Bootstrap](bootstrap.md) and [Phase 3 - Run](run.md) guides.
- Plan and approve before apply, `Remove-MLOpsAccelerator`, `-Upgrade`, `-Interactive` and `Grant-MLOpsStorageAccess`.
- `install-local.ps1` for local install and uninstall, since the module is not published yet.
- Default environments are `dev`, `test` and `prod`.
- Pipelines are numbered by phase.

### Changed

- **[Important]** Docs renumbered: Planning 0, Prerequisites 1, Bootstrap 2, Run 3.
- Python is pinned to 3.14. Held back on purpose: `azurerm` below 5.0 (AVM requirement), `pyarrow` below 26 (mlflow cap) and `azureml-mlflow` 1.60.0.
- Generated files are LF-only on every OS.
- CI runs on Ubuntu, Windows and macOS.

### Fixed

- Python lookup in `Update-MLOpsAcceleratorVersion` now works on Windows (`python`, `python3` and `python3.14`).
- The scenario test matrix uses the OS temp folder instead of `$env:TMPDIR`.

### Known gaps

- Compute sizes are not inputs yet.
- The bootstrap sets no approval reviewers and does not register Azure DevOps pipelines.
- No managed feature store pack yet.
- Not published to the PowerShell Gallery.

See [Gap analysis versus ALZ](reference/alz-gap-analysis.md) for the full comparison.
