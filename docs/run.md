---
title: "Phase 3 - Run"
weight: 40
---

Bootstrap has created the repository, identity and environments. Now push the generated project and run its pipelines.

{{% callout style="warning" %}}
Nothing in this accelerator has been applied to a real subscription yet. Run it first in a throwaway subscription.
{{% /callout %}}
## 1. Push the generated project

```powershell
cd ./my-mlops
git init -b main; git add .; git commit -m "Initial commit"
git remote add origin <repo url printed by the bootstrap>; git push -u origin main
```

## 2. Add approvals (recommended)

The bootstrap creates one environment per stage (`dev`, `test`, `prod` by default) but does **not** add required reviewers. Add them yourself before the first run: in GitHub, open Settings, then Environments, select `prod` and add Required reviewers; in Azure DevOps, open Pipelines, then Environments, and use Approvals and checks. The approval gates the job that follows it, which here runs `terraform plan` and `apply` together, so reviewers approve before the plan runs.

## 3. Run the pipelines

{{< tabs >}}
{{% tab title="GitHub" %}}
1. Open the repository, then **Actions**.
2. **2 - infra** runs on every push to `main` that touches `infra/`. To run it by hand choose **Run workflow** on `main`. It validates (fmt, validate, Checkov), then deploys `dev`, then `test`, then `prod`, each waiting for its environment approval.
3. When infra is green, run **3 - ml-train** (**Run workflow**, pick an environment). It runs unit tests, submits the AML training pipeline and registers the model.
4. Run **4 - ml-deploy** to create the endpoint (scenarios 2-4, 6-9, 11 online; 5 batch). Scenario 6 shifts traffic 10% then 100%. Scenario 8 uses **4 - ml-promote** to copy the model through the shared registry first.
{{% /tab %}}
{{% tab title="Azure DevOps" %}}
1. The bootstrap creates the repo, environments, variable groups and service connections, but **not the pipelines**. Under **Pipelines**, choose **New pipeline**, then **Azure Repos Git**, and register each YAML under `pipelines/` (`infra.yml`, `ml-train.yml`, `ml-deploy.yml`, plus `ml-promote.yml` for scenario 8).
2. Run `infra` and approve each environment as prompted, then `ml-train`, then `ml-deploy`.
{{% /tab %}}
{{< /tabs >}}
{{% callout style="note" %}}
Scenarios with private networking (2-4, 11) need self-hosted agents or runners that can reach the workspace; hosted agents will fail at the AML steps.
{{% /callout %}}
## 4. Verify each phase

| After | Check |
|---|---|
| infra | Resource group per environment, AML workspace reachable in the portal |
| ml-train | A job in the Jobs page in Azure ML studio and a registered model |
| ml-deploy | Endpoint shows *Succeeded*; send a sample request (see the generated README) |

## Run locally instead

The pipelines are thin wrappers, so you can run a stage yourself with an identity that has Contributor on the subscription.

```powershell
az login --tenant <tenant-id> --use-device-code
az account set --subscription <subscription-id>
# Terraform
terraform -chdir=infra init -backend-config="..."   # see the init step in infra.yml for the values
terraform -chdir=infra plan -var-file=envs/dev.tfvars -out=dev.tfplan
terraform -chdir=infra apply dev.tfplan
```

For Bicep use `az deployment group what-if` then `create` with the generated `.bicepparam`. There is no `deploy-local.ps1` yet.

## Clean up

If you were testing, remove everything the bootstrap created (repo, identity, state storage, environments):

```powershell
Remove-MLOpsAccelerator -InputFile inputs.yaml -ProjectPath ./my-mlops
```

Destroy the workload resource groups first (`terraform destroy` per environment, or delete the resource groups), because the bootstrap removal does not touch them. Soft-deleted Key Vaults and AML workspaces can block re-creation under the same names until purged.
