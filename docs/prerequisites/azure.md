---
title: "Azure subscriptions and permissions"
weight: 2
---

## Subscription

One subscription hosts the bootstrap and all environments by default (`subscription_id` in the inputs). Use separate subscriptions per environment later by customizing the generated parameter files; that is not an input today.

## Permissions for the person running the bootstrap

The bootstrap creates a resource group, a state storage account, a user-assigned managed identity with federated credentials, and role assignments. You need at the subscription (or a parent scope):

- **Owner**, or **Contributor** plus **Role Based Access Control Administrator** or **User Access Administrator**

No Microsoft Entra directory permissions are required: the identity is an Azure managed identity, not an app registration.

The deploy identity that the pipelines use receives **Contributor**, **Role Based Access Control Administrator** and **Resource Policy Contributor** (for the [policy guardrails](../policy/_index.md)) at subscription scope, and **Storage Blob Data Contributor** on the state account. Scope these down for production.

## Resource providers

Register these before the first deployment (the accelerator does not register them for you):

```powershell
'Microsoft.MachineLearningServices','Microsoft.Storage','Microsoft.KeyVault','Microsoft.ContainerRegistry',
'Microsoft.OperationalInsights','Microsoft.Insights','Microsoft.ManagedIdentity','Microsoft.Authorization',
'Microsoft.PolicyInsights','Microsoft.Network','Microsoft.CognitiveServices','Microsoft.Consumption' | ForEach-Object { az provider register --namespace $_ }
```

See [Resource providers](../reference/resource-providers.md) for what each one is for.

## Quota and region

- Check vCPU quota for the compute SKU in your region (`az vm list-usage -l <region>`), for each environment you will run training in.
- Pick a region that offers Azure ML managed online endpoints and, for scenario 10, AI Foundry.
- Three environments multiply cost; see the [parameter checklist](../planning/parameter-checklist.md#environments-and-cost).

## Private scenarios

Scenarios 2 to 4 (managed VNet and your own VNet) and 11 (existing platform) disable public access. GitHub-hosted and Microsoft-hosted agents cannot reach the workspace. Provide a self-hosted agent or runner on a network that reaches the private endpoints before running `ml-train` and `ml-deploy`.

Scenario 11 also needs the existing subnet, Log Analytics workspace and private DNS zone IDs, and rights to create private endpoints in that subnet and link records in those zones.

## Sign in

```powershell
az login --tenant <tenant-id>
az account set --subscription <subscription-id>
```
