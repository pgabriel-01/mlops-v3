---
title: "Cleanup"
weight: 1
---

## How do I remove everything?

1. Destroy the workload resources first, one environment at a time: `terraform destroy` in `infra/` (Terraform), or delete the environment resource groups (Bicep).
2. Remove the bootstrap resources (identity, state storage, repository and environments):

   ```powershell
   Remove-MLOpsAccelerator -InputFile inputs.yaml -ProjectPath ./my-mlops
   ```

   It does not touch the workload resource groups, which is why step 1 comes first.

## I redeployed and got a name conflict

Key Vaults (purge protection) and Azure ML workspaces stay soft-deleted after a destroy and keep their names reserved. Either purge them (`az keyvault purge`, or purge the workspace), or set a different `name_suffix` in `inputs.yaml` and redeploy. Policy can block purging; the vaults then expire on their own.

## Do the budgets and policy assignments get removed?

Yes, when you destroy the environment. Budgets and the policy assignments are part of the environment's infrastructure.
