---
title: "Advanced"
weight: 35
---

Options beyond the basic bootstrap and run steps.

## Private networking for the bootstrap

Set `use_private_networking: true` (GitHub) to deploy self-hosted Azure Container Instances runners in a new VNet with a NAT gateway, using the AVM `cicd-agents-and-runners` module as the ALZ Accelerator does. The state storage account then gets a private endpoint and public access is turned off. `runner_label` defaults to `self-hosted`.

- Runner registration uses a GitHub PAT with repo admin rights. `-Deploy` reuses `GITHUB_TOKEN` (or `gh auth token`); set `TF_VAR_github_runners_token` to override.
- Review `runners_vnet_address_space` (default `10.250.0.0/24`) so it does not overlap your ranges.
- This is not verified live yet (tracked in [issue 31](https://github.com/pgabriel-01/mlops-v3/issues/31)). Azure DevOps Managed DevOps Pools are not generated yet ([issue 33](https://github.com/pgabriel-01/mlops-v3/issues/33)).

## Bring your own runners

Set `runner_label` to the label of your runners (for example an ARC scale set on a private AKS cluster). Every generated GitHub workflow then uses it in `runs-on`. The runners must reach the state storage account and, for private scenarios, the workspace private endpoints.

## Multiple workloads

`workloads: [taxi, churn]` renders the platform once and one folder, set of assets and set of pipelines per workload. Names are 3 to 16 lowercase letters, digits and hyphens.

## Upgrades

See the [upgrade guide](upgrade-guide.md).
