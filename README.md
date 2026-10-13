# MLOps v3 Accelerator

A PowerShell module that turns one inputs file into a ready-to-run Azure Machine Learning MLOps repository: bootstrap (state, identity, repo wiring), infrastructure, CI/CD and a tabular training workload. Modeled on the ALZ Accelerator.

| Choice | Options |
|---|---|
| IaC | Terraform, Bicep |
| CI/CD | GitHub Actions, Azure DevOps |
| Scenario | `tabular` (taxi CSV; Parquet/feature store planned) |

## Quick start
```powershell
Install-PSResource powershell-yaml
Import-Module ./src/MLOpsAccelerator/MLOpsAccelerator.psd1
Copy-Item inputs.example.yaml my-inputs.yaml   # edit
Deploy-MLOpsAccelerator -InputFile my-inputs.yaml -OutputPath ./my-mlops          # generate
Deploy-MLOpsAccelerator -InputFile my-inputs.yaml -OutputPath ./my-mlops -Deploy  # generate + bootstrap
Test-MLOpsAcceleratorVersion          # warn about outdated pins
Update-MLOpsAcceleratorVersion        # bump pins only if Python packages still resolve together
```
Requires PowerShell 7.4+, and for `-Deploy`: `az` (logged in), `terraform`, plus `GITHUB_TOKEN` or `AZDO_PERSONAL_ACCESS_TOKEN`.

## Versions
`versions.lock.json` is the single source of truth. Python is pinned to **3.14**, not 3.15: 3.15 is still a release candidate and `pyarrow` has no wheels for it. The whole stack was checked with `pip check` on 3.14 and the training pipeline run end to end. Bump `python` in the lock once 3.15 wheels exist. `azureml-featurestore` supports only Python <= 3.12 (relevant to the planned Phase 2, which runs on Spark).

## Design notes / best-practice mapping
- Security (WAF/CAF): OIDC/workload identity federation, no secrets; Key Vault with RBAC and purge protection; Terraform state in Azure Storage with Entra auth; checkov in CI; per-environment approvals through GitHub environments / ADO environments.
- Operations: Log Analytics + App Insights; dev -> prod promotion, one state file per environment.
- MLOps: pipeline (prep, train, evaluate, register), model registry, managed online endpoint with safe rollout.

## Known limitations
- Bootstrap is always Terraform (like ALZ), even when IaC is Bicep.
- Deploy identity gets Contributor + RBAC Administrator at subscription scope; scope it down for production.
- `private_networking: true` only disables public access; no VNet/private endpoints are created yet.
- Not verified against a live Azure subscription: bootstrap apply, AML runtime with Python 3.14 conda image, endpoint deployment.
- Phase 2 (Parquet transactions data + managed feature store) is not implemented beyond an optional feature store resource.

## Develop
`Invoke-Pester ./tests`. Rendered output is additionally validated with `terraform validate`, `az bicep build` and the generated pytest (see `.github/workflows/ci.yml`).
