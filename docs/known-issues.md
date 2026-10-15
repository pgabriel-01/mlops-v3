---
title: Known issues
weight: 3
---

Issues you may hit, with workarounds. Each entry says when it was found and when it was fixed. For fixes and changes, see [What's new](whats-new.md).

{{% callout style="warning" title="Live coverage is partial" %}}
Scenarios 1 to 12 have been applied to a real subscription on Terraform and Bicep. Scenario 12 (`rag-llmops`) passed once in `centralus` after `eastus2` ran out of Azure AI Search capacity. The sample documents are for a fictional company; replace them with your own. Several other parts have not; see [Live deployment coverage](#live-deployment-coverage).
{{% /callout %}}

## Bootstrap: new role needed for policy guardrails

Projects bootstrapped before `policy_mode` existed lack the **Resource Policy Contributor** role on the deploy identity. Contributor cannot write policy assignments, so the first deploy fails with an authorization error.

Workaround: re-run the bootstrap (it adds the role), or set `policy_mode: none`.

## Policy: public-access policy is skipped in public scenarios

The "ML workspaces should disable public network access" policy is only assigned when the scenario is private. In public scenarios it would always be non-compliant, so it is left out on purpose.

## Policy: compliance results are delayed

New assignments can take up to 30 minutes to report compliance. See the [Policy FAQ](policy/faq.md).

## Azure DevOps: pipelines are not registered

Bootstrap creates the repo, service connection and variables, but does not register the pipelines. Create them from the generated YAML files in the repository.

## Bootstrap: no required reviewers on environments

Environments are created without approval reviewers. Add reviewers manually for production.

## Dependency holds

Some pins are held on purpose, and are recorded in `versions.lock.json`:

- `provider:azurerm` is held below 5.0, because the Azure Verified Modules require it.
- `pypi:pyarrow` is held below 26.
- `pypi:azureml-mlflow` is held at 1.60.0.

## Cost estimates are list price

`scripts/Get-ScenarioCostEstimates.ps1` uses the Azure Retail Prices API. The figures are list price and order of magnitude only.

## No Responsible AI automation

Fairness, explainability and content-safety checks are not generated yet. See [Responsible AI](reference/responsible-ai.md).

## Feature store scenario is infrastructure only

Scenario 7 creates the feature store workspace but no feature set, offline store or materialization, and the training pipeline does not use it. See [Managed feature store](scenarios/07-feature-store.md).

## Live deployment coverage

The `e2e.yml` workflow applies a scenario, checks the workspace exists, then destroys everything. Results for the `dev` environment (workload IaC only; the bootstrap is not covered):

| Scenario | Terraform | Bicep | Run |
|---|---|---|---|
| 1 basic-public | Verified | Verified | 38554509708 |
| 2 managed-vnet-internet | Verified | Verified | 38613440753 |
| 3 managed-vnet-approved | Verified | Verified | 38616830510 |
| 4 byo-vnet | Verified | Verified | 38634380586 |
| 5 batch-scoring | Verified | Verified | 38638768681 |
| 6 online-bluegreen | Verified | Verified | 38643944228 |
| 7 feature-store | Verified | Verified | 38660126809 |
| 8 registry-promotion | Verified | Verified | 38668463752 |
| 9 governance | Verified | Verified | 38691269136 |
| 10 genai-foundry | Verified | Verified | 38692709950 |
| 11 existing-platform | Verified | Verified | 38696125604 |
| 12 rag-llmops | Verified | Verified | 38788861939 |

Live runs found and fixed these problems: Terraform zone sets that were unknown at plan time, duplicate storage private endpoint names, compute created before the workspace private endpoint (now explicit `depends_on`), Standard ACR rejecting the default `Deny` network action, storage and Key Vault needing explicit `Allow` ACLs for public scenarios, a Terraform conditional with mismatched object types for the managed network, and the OIDC token expiring during long applies.

The GitHub and Terraform bootstrap apply is verified live (46 resources, October 15, 2026). A pipeline run after it failed at `terraform init` with the 403 described below, because the test subscription's policy turns state storage public access off. Not verified live: the Bicep and Azure DevOps bootstraps, private runners and private state storage, Azure DevOps, separate plan and apply identities, Managed DevOps Pools, the `rai` option, the scenario 7 feature-set pack and endpoint deployment.

## Soft-deleted names and managed-network rules

- Key Vaults (purge protection) and AML workspaces stay soft-deleted after a destroy, which blocks redeploying the same names. Change the `suffix` (Bicep param or Terraform variable) before redeploying.
- Managed-network private endpoint outbound rules for storage, Key Vault, ACR and the workspace are created by the service. The templates define only FQDN rules.
- Every private scenario (2, 3, 4 and 11) is verified live on Terraform and Bicep. The private runners and private state storage from the bootstrap are not.

## Terraform state storage and runner networking

The bootstrap state storage account is Entra-only (shared keys off) but uses a public endpoint so GitHub-hosted runners can reach it. If your tenant policy forces storage public access off, `terraform init` in the pipeline fails with 403. Set `runner_label` to a self-hosted runner label (for example an ARC scale set on a private AKS cluster in a VNet with access to the account). The reference pattern is the private AKS and ARC bootstrap in `retail-demand-forecasting-mlops/runner-bootstrap`; it is not generated by this accelerator yet.

## GitHub OIDC subjects

New GitHub repositories issue ID-based subjects (`repo:owner@ownerId/repo@repoId:environment:env`). The bootstrap builds the federated credentials with these IDs.

## Docs site (GitHub Pages)

`pages.yml` only runs when the repository variable `PAGES_ENABLED` is `true`. This repository is public, Pages is enabled (source: GitHub Actions) and the variable is set. For a fork or a private copy, enable Pages in Settings (private repositories need a paid plan), then set the variable.

## End-to-end workflow

`.github/workflows/e2e.yml` plans (and optionally applies, verifies and destroys) the scenarios you list, for Terraform and Bicep in a dedicated test subscription.

- PRs: add the `safe-to-test` label to run plan or what-if only.
- Apply: run it manually with `apply: true` and a scenario list. Use `scenarios: all` for the full matrix (scenarios 1 to 12, Terraform and Bicep, 24 jobs, 4 at a time). A full run has not been completed yet, and there is no scheduled run, because the gate needs a manual approval and a full run costs real money.

Policy: run only the affected scenarios when a change touches them, and run the full set before a release tag and after changes to shared IaC modules. Each job has its own resource group, suffix and deployment name, and failures do not stop the other jobs.
- Setup: an `e2e` environment with `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` (OIDC identity with Contributor and RBAC Administrator, plus a custom role allowing `Microsoft.Authorization/locks/*` for the governance scenario).
- Each run uses a unique `name_suffix`, so soft-deleted Key Vaults and workspaces never collide. Purge can be blocked by policy; the vaults then expire on their own.
- It tests the workload IaC only. The GitHub and Azure DevOps bootstrap is tested with `tests/Invoke-E2E.ps1`.

## Private runners and private state storage

Set `use_private_networking: true` (GitHub) to deploy self-hosted ACI runners in a new VNet with a NAT gateway (AVM `cicd-agents-and-runners`, as in the ALZ Accelerator). The state storage then gets a private endpoint and public access is disabled. `runner_label` defaults to `self-hosted`.

- The runner registration uses a GitHub PAT with repo admin rights. `-Deploy` reuses `GITHUB_TOKEN` (or `gh auth token`); set `TF_VAR_github_runners_token` to override.
- Not yet verified live. Azure DevOps (Managed DevOps Pools) is not generated yet.

## ADLS data is not an MLTable

The bundled `taxi-csv`, `taxi-parquet` and `nyc-taxi-open` samples register as MLTable assets. `data_source: adls` registers a single `uri_file`, because `src/prep.py` parses MLTable by hand and reads only local paths. MLTable for ADLS needs `prep.py` support and a live run.

## Ubuntu 26.04 and `ubuntu-latest`

GitHub moves the `ubuntu-latest` label to Ubuntu 26.04 between October 19 and November 19, 2026. Generated workflows use the `runner_label` input (default `ubuntu-latest`), so they move with it. This repository's CI runs the tests on `ubuntu-26.04` in a non-blocking canary job first. If a generated workflow breaks after the move, set `runner_label: ubuntu-24.04` to pin the old image and open an issue.
