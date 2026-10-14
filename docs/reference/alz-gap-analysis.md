---
title: "Gap analysis vs the ALZ PowerShell accelerator"
weight: 3
---

Compared against `Azure/ALZ-PowerShell-Module` (`Deploy-Accelerator`). ALZ keeps bootstrap and starter modules in separate repos and downloads them by version.

| ALZ capability | Ours | Priority |
|---|---|---|
| Interactive prompts for missing inputs (`Request-AcceleratorConfigurationInput`, menu selection) | Inputs file only | Medium |
| `Test-AcceleratorRequirement` (PowerShell, az, git, gh/azdo CLI, yaml module, env vars, network) | None; errors surface mid-run | High |
| `-destroy` and `Remove-*Accelerator` cleanup commands | None | High |
| `-upgrade`, `-replace_files`, `-clean_bootstrap_folder`, `-clear_cache` | Output is regenerated; no upgrade or merge logic | Medium |
| `-auto_approve` and a plan/apply split for bootstrap | `-Deploy` applies directly | Medium |
| Versioned, downloadable bootstrap and starter modules, with overrides | Templates ship inside the module | Low for now |
| Tfvars to JSON conversion, computed config such as availability zones and region data | Not needed so far | Low |
| Retry and timeout options for HTTP, terraform version management | None | Low |
| Grant roles helper (`Grant-SubscriptionCreatorRole`) | Role prerequisites are documented only | Medium |
| Wiki docs, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT, SUPPORT, release packaging | README and `docs/` only | Medium before publishing |
| End-to-end tests against real Azure | Offline render, validate and Pester only | High |

## Suggested next steps
1. `Test-MLOpsAcceleratorRequirement` (new public command, called by `Deploy-MLOpsAccelerator` unless skipped).
2. `-Destroy` and a cleanup command for the bootstrap resources.
3. Plan-then-approve flow for `-Deploy`.
4. Community files and release packaging before the first push.

## Status
Done locally: requirements check, plan-then-approve and `-AutoApprove`, `-Destroy` / `Remove-MLOpsAccelerator`, `-Upgrade`, `-Interactive`, `Grant-MLOpsStorageAccess`, community files, release workflow, a manual E2E script (`tests/Invoke-E2E.ps1`, not yet run against Azure).

Deliberately not done: versioned downloadable template packs, tfvars-to-JSON conversion, HTTP retry options, Terraform version management (templates ship inside the module, so these add no value yet). A wiki is deferred; `docs/` is the doc set.
