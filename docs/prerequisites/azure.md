# Azure subscriptions and permissions

## Subscription

One subscription hosts the bootstrap and all environments by default (`subscription_id` in the inputs). Use separate subscriptions per environment later by customising the generated parameter files; that is not an input today.

## Permissions for the person running the bootstrap

The bootstrap creates a resource group, a state storage account, a user-assigned managed identity with federated credentials, and role assignments. You need at the subscription (or a parent scope):

- **Owner**, or **Contributor** plus **Role Based Access Control Administrator** / **User Access Administrator**

No Microsoft Entra directory permissions are required: the identity is an Azure managed identity, not an app registration.

The deploy identity that the pipelines use receives **Contributor** and **Role Based Access Control Administrator** at subscription scope, and **Storage Blob Data Contributor** on the state account. Scope these down for production.

## Resource providers

Register these before the first deployment (the accelerator does not register them for you):

```powershell
'Microsoft.MachineLearningServices','Microsoft.Storage','Microsoft.KeyVault','Microsoft.ContainerRegistry',
'Microsoft.OperationalInsights','Microsoft.Insights','Microsoft.ManagedIdentity','Microsoft.Authorization',
'Microsoft.Network','Microsoft.CognitiveServices' | ForEach-Object { az provider register --namespace $_ }
```

`Microsoft.CognitiveServices` is for scenario 10 (AI Foundry); `Microsoft.Network` for scenarios with networking. `Microsoft.Consumption` / `Microsoft.Billing` budgets (scenarios 9 and 11) also need `Microsoft.Consumption`.

## Quota and region

- Check vCPU quota for the compute SKU in your region (`az vm list-usage -l <region>`), for each environment you will run training in.
- Pick a region that offers Azure ML managed online endpoints and, for scenario 10, AI Foundry.
- Three environments multiply cost; see [parameter checklist](../parameter-checklist.md#environments-and-cost).

## Private scenarios

Scenarios 4 (BYO VNet), 11 (existing platform) and the managed-VNet modes disable public access. GitHub-hosted and Microsoft-hosted agents cannot reach the workspace. Provide a self-hosted agent/runner on a network that reaches the private endpoints before running `ml-train` and `ml-deploy`.

Scenario 11 also needs the existing subnet, Log Analytics workspace and private DNS zone IDs, and rights to create private endpoints in that subnet and link records in those zones.

## Sign in

```powershell
az login --tenant <tenant-id>
az account set --subscription <subscription-id>
```
