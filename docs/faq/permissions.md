---
title: "Permissions"
weight: 2
---

## What does the person running the bootstrap need?

**Owner** on the subscription, or **Contributor** plus **Role Based Access Control Administrator** (or **User Access Administrator**). No Microsoft Entra directory permissions are required, because the identity is an Azure managed identity and not an app registration. See [Azure subscriptions and permissions](../prerequisites/azure.md).

## What does the pipeline identity get?

**Contributor**, **Role Based Access Control Administrator** and **Resource Policy Contributor** at subscription scope, and **Storage Blob Data Contributor** on the state account. Scope them down for production if your organization requires it.

## Why does the first deploy fail with an authorization error on policy?

Contributor cannot write policy assignments. Projects bootstrapped before `policy_mode` existed lack the Resource Policy Contributor role. Re-run the bootstrap, or set `policy_mode: none`. See [known issues](../known-issues.md).

## Why does `terraform init` fail with 403 on the state account?

The state account is Entra-only. If your policy forces public access off, the pipeline cannot reach it from GitHub-hosted runners. Use `use_private_networking: true` (GitHub) or a self-hosted runner and `runner_label`. See [Advanced](../advanced.md).

## Do I need a GitHub or Azure DevOps token?

Yes, for the bootstrap only. See the [GitHub](../prerequisites/github.md) and [Azure DevOps](../prerequisites/azure-devops.md) prerequisites. The generated pipelines authenticate to Azure with workload identity federation, not secrets.
