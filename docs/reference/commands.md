---
title: "Commands"
weight: 1
---

The module exports these commands. Use `Get-Help <command> -Full` for parameters and examples.

| Command | Purpose |
|---|---|
| `Test-MLOpsAcceleratorRequirement` | Pre-flight check of tools, `az login`, tokens and network. Also runs before `-Deploy`. |
| `Test-MLOpsModelQuota` | Checks regional model and Azure AI Search quota for the `rag-llmops` scenario. Also runs before `-Deploy` for that scenario. |
| `Get-MLOpsScenario` | List the scenarios and their ids. |
| `New-MLOpsInputFile` | Write an inputs file for a scenario. |
| `Test-MLOpsAcceleratorInput` | Validate an inputs file against the schema. |
| `Deploy-MLOpsAccelerator` | Generate the project. `-Deploy` plans, asks for approval and applies the bootstrap (`-AutoApprove` skips the prompt). `-Upgrade` regenerates an existing project. `-Destroy` tears down the bootstrap. `-Interactive` prompts for the inputs. |
| `Remove-MLOpsAccelerator` | Destroy the bootstrap and optionally delete the local folder. |
| `Grant-MLOpsStorageAccess` | Give the workspace identity Storage Blob Data Reader for `data_source: adls`. |
| `Test-MLOpsAcceleratorVersion` | Compare the pinned versions in `versions.lock.json` with the latest releases. |
| `Update-MLOpsAcceleratorVersion` | Update the pinned versions that still resolve together. |

## Design

- **Security:** OIDC and workload identity federation with no stored secrets, Key Vault with RBAC and purge protection, Terraform state in Azure Storage with Entra authentication, checkov in CI, and per-environment approvals.
- **Operations:** Log Analytics and Application Insights, promotion from `dev` to `test` to `prod`, and one state file per environment.
- **MLOps:** a training pipeline (prepare, train, evaluate, register), a model registry and a managed online endpoint with safe rollout.
- **Azure Verified Modules:** see [Azure Verified Modules](azure-verified-modules.md).
- **Versions:** `versions.lock.json` is the single source of truth. Python is pinned to 3.14 because 3.15 is still a release candidate and `pyarrow` has no wheels for it.
