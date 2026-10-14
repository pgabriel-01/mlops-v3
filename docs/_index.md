---
title: "Getting started"
weight: 1
---

A PowerShell module that turns one inputs file into a ready-to-run Azure Machine Learning MLOps repository: bootstrap, infrastructure (Terraform or Bicep on Azure Verified Modules), CI/CD (GitHub Actions or Azure DevOps) and a training workload.

The accelerator follows four phases:

0. [Planning](planning/_index.md): optional decisions that map to `inputs.yaml`.
1. [Prerequisites](prerequisites/_index.md): tools, credentials, permissions and quota.
2. [Bootstrap](bootstrap.md): run the PowerShell module to create the repository, identity and environments.
3. [Run](run.md): push the generated project and deploy through CI/CD.

Then [customise](options/_index.md) it, or compare [scenarios](scenarios/_index.md).

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
Generated output is validated offline (render, `terraform validate`, `az bicep build`, pytest). It has not yet been applied to a live Azure subscription.
{{% /callout %}}
