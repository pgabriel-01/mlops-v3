---
title: Known issues
weight: 3
---

Issues you may hit, with workarounds. Each entry says when it was found and when it was fixed. For fixes and changes, see [What's new](whats-new.md).

{{% callout style="warning" title="Not yet applied to live Azure" %}}
The end-to-end deployment test (`tests/Invoke-E2E.ps1`) has not been run against a real subscription. Expect more entries here after the first real runs.
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

Only scenario 1 (basic-public, Terraform, `dev`) has been applied to a real subscription: 43 resources created, the compute cluster and both policy assignments confirmed, then destroyed cleanly. That run found and fixed two bugs (Standard container registry with zone redundancy; workspace module reading the resource group before it existed). The other scenarios, Bicep and the bootstrap are validated in CI but have not been deployed.


## Soft-deleted names and managed-network rules

- Key Vaults (purge protection) and AML workspaces stay soft-deleted after a destroy, which blocks redeploying the same names. Change the `suffix` (Bicep param or Terraform variable) before redeploying.
- Managed-network private endpoint outbound rules for storage, Key Vault, ACR and the workspace are created by the service. The templates define only FQDN rules.
- Bicep scenario 2 (managed VNet) is verified live; Terraform private scenarios are not yet.
