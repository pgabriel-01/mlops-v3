---
title: "MLOps v3 Documentation"
weight: 1
---

Welcome to the MLOps v3 technical documentation site. It explains how to deploy and manage Azure Machine Learning MLOps using the accelerator we provide: a PowerShell module that turns one inputs file into a ready-to-run repository with bootstrap, infrastructure (Terraform or Bicep on Azure Verified Modules), CI/CD (GitHub Actions or Azure DevOps) and a training workload.

Use the navigation links on the left to explore the documentation.

Please see the [MLOps v2 guidance on Learn](https://learn.microsoft.com/azure/machine-learning/concept-model-management-and-deployment) for an introduction to the concepts this accelerator builds on.

## The MLOps journey

The MLOps journey is a multi-step process. It starts with planning and bootstrapping your environment and ends with workloads training and serving models.

### Plan your deployment

Decide the scenario, network mode, environments, data source and tooling before you run anything. Each decision maps to a key in `inputs.yaml`.

See the [planning](planning/_index.md) section and the [prerequisites](prerequisites/_index.md) for more information.

### Bootstrap your environment

The bootstrap is the first step of the journey. It sets up the foundational components used to deploy and manage the platform: the repository or project, a managed identity with federated credentials, environments, and a remote state store. In this step we make sure you have the correct access and a subscription to work with.

See the [bootstrap](bootstrap.md) section for more information.

### The MLOps platform

The platform is the core of the journey. It provides the governance, networking and security components that workloads build on.

Included in the platform are:

- **Azure Machine Learning workspace** - one per environment (`dev`, `test`, `prod`), with storage, key vault, container registry and monitoring.
- **Policy** - guardrail policy assignments that audit or enforce secure settings. See [policy](policy/_index.md).
- **Role-based access control (RBAC)** - least-privilege roles for the pipeline identity and the workspace.
- **Networking** - public, managed virtual network or bring-your-own virtual network, depending on the [scenario](scenarios/_index.md).
- **Budgets and alerts** - cost guardrails per environment.

### Workloads

Workloads are the models and pipelines that run on the platform. Each workload gets its own folder, Azure ML assets and train and deploy pipelines. Several workloads can share the one platform with the `workloads` input.

See [run](run.md) and the [customization options](options/_index.md) for more information.

Questions or problems? See the [FAQ](faq/_index.md), [troubleshooting](troubleshooting.md), [advanced options](advanced.md) and [known issues](known-issues.md).

To get started, look at the [quick start](getting-started.md) or the [bootstrap your environment](bootstrap.md) process.

## What gets created

{{< tabs >}}
{{% tab title="GitHub" %}}
- Azure: user-assigned managed identity with federated credentials, role assignments
- Private repository containing the generated project
- One GitHub environment per stage (`dev`, `test`, `prod`)
- Actions variables for subscription, tenant and identity
- Workflows: infra, ml-train, ml-deploy, ml-promote
{{% /tab %}}
{{% tab title="Azure DevOps" %}}
- Azure: user-assigned managed identity with federated credentials, role assignments
- Repository, environments and variable groups in your project
- Service connections using workload identity federation
- Pipeline definitions in `pipelines/` (register them manually)
{{% /tab %}}
{{% tab title="Local files only" %}}
- The generated project is written to disk; wire your own VCS and pipelines
{{% /tab %}}
{{< /tabs >}}
Each environment then deploys an Azure ML workspace with storage, key vault, container registry and monitoring. Private scenarios add networking.

{{% callout style="warning" title="Status" %}}
Generated output is validated offline (render, `terraform validate`, `az bicep build`, pytest). Scenarios 1 to 3 are also verified live (Terraform and Bicep); see [Known issues](known-issues.md#live-deployment-coverage).
{{% /callout %}}
