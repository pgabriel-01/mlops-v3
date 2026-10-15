---
title: "Resource providers"
weight: 75
---

Azure only lets you deploy a resource type if the subscription is registered for its resource provider. Azure often registers providers on first use, but that needs permission and can fail mid-deployment, so register them up front in every subscription you deploy to (one per environment if you use separate subscriptions).

## Required providers

| Provider | Needed for | Scenarios |
|---|---|---|
| `Microsoft.MachineLearningServices` | Workspace, compute, registry | All |
| `Microsoft.Storage` | Workspace storage, Terraform state, ADLS data | All |
| `Microsoft.KeyVault` | Workspace Key Vault | All |
| `Microsoft.ContainerRegistry` | Workspace container registry | All |
| `Microsoft.OperationalInsights` | Log Analytics | All |
| `Microsoft.Insights` | Application Insights, diagnostics | All |
| `Microsoft.ManagedIdentity` | Deploy identity, workspace identities | All |
| `Microsoft.Authorization` | Role assignments, policy assignments (registered by default) | All |
| `Microsoft.PolicyInsights` | Policy compliance results | All unless `policy_mode: none` |
| `Microsoft.Network` | VNets, private endpoints, private DNS | 2, 3, 4, 9 and any private scenario |
| `Microsoft.CognitiveServices` | AI Foundry, model deployments | 10, 12 |
| `Microsoft.Search` | Azure AI Search | 12 |
| `Microsoft.Consumption` | Budget alerts | 9, or when `budget_amount` is set |

Providers marked "registered by default" need no action. See the [Azure list of providers by service](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-services-resource-providers).

## Register them

```powershell
'Microsoft.MachineLearningServices','Microsoft.Storage','Microsoft.KeyVault','Microsoft.ContainerRegistry',
'Microsoft.OperationalInsights','Microsoft.Insights','Microsoft.ManagedIdentity','Microsoft.PolicyInsights',
'Microsoft.Network','Microsoft.CognitiveServices','Microsoft.Search','Microsoft.Consumption' |
  ForEach-Object { az provider register --namespace $_ }
```

Registration takes a few minutes. Check progress with `az provider show -n Microsoft.MachineLearningServices --query registrationState`.

Registering needs the `*/register/action` permission, which the Contributor role includes. `Test-MLOpsAcceleratorRequirement` reports the unregistered ones it checks.

## Troubleshooting

- `MissingSubscriptionRegistration` or `The subscription is not registered to use namespace ...`: register that namespace and run the deployment again.
- Deployment fails with `Conflict` right after registering: wait until the state is `Registered`.
- Extra resources you add yourself may need more providers. Check the resource's provider namespace.
