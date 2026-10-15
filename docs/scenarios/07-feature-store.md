---
title: "7 - Managed feature store"
weight: 7
---

Adds an Azure ML managed feature store workspace. The Parquet data source and a feature set are planned as a separate feature store workload pack.

| | |
|---|---|
| Id | `feature-store` |
| Network | public |
| Serving | online |
| Adds | Managed feature store workspace |
| IaC and CI/CD | Terraform or Bicep; GitHub or Azure DevOps |

Adds a managed feature store workspace alongside the project workspace. The feature store always gets a managed network in `AllowInternetOutbound` mode, because serverless Spark needs one and Microsoft documents it as the only supported mode for feature stores ([Tutorial 6](https://learn.microsoft.com/azure/machine-learning/tutorial-network-isolation-for-feature-store)). The workspace sets the Spark runtime to 3.4.0 and has no container registry, because a managed network requires a Premium registry and the feature store does not need one.

{{% callout style="warning" title="Infrastructure only" %}}
This scenario creates the feature store workspace (`kind: FeatureStore`) and nothing else. The generated training pipeline does **not** define, register or materialize a feature set, and does not read features from the store. The infrastructure is applied, verified and destroyed live on Terraform and Bicep by the `e2e.yml` workflow. The feature set workload pack is not verified live. The Microsoft tutorial [Develop and register a feature set](https://learn.microsoft.com/azure/machine-learning/tutorial-get-started-with-feature-store) covers the missing parts: a feature set spec, a Spark transformation, an offline store, a materialization identity and role assignments.
{{% /callout %}}

## Use it

```powershell
New-MLOpsInputFile -Scenario feature-store -Path inputs.yaml -Iac terraform -Cicd github
```

See the [cost estimates](_index.md#estimated-fixed-monthly-cost) and the [prerequisites](../prerequisites/_index.md).

## Microsoft documentation

- <https://learn.microsoft.com/azure/machine-learning/concept-what-is-managed-feature-store>
