---
title: "Comparison with the ALZ PowerShell accelerator"
weight: 3
---

This page compares the accelerator with `Azure/ALZ-PowerShell-Module` (`Deploy-Accelerator`). ALZ keeps bootstrap and starter modules in separate repositories and downloads them by version. This accelerator ships its templates inside the module.

| ALZ capability | Here | Status |
|---|---|---|
| Interactive prompts for missing inputs | `Deploy-MLOpsAccelerator` with no inputs file, or `-Interactive` | Done |
| Requirements check (PowerShell, Azure CLI, Git, GitHub CLI, the YAML module, tokens and network) | `Test-MLOpsAcceleratorRequirement`, run before `-Deploy` unless skipped | Done |
| Destroy and cleanup commands | `-Destroy` and `Remove-MLOpsAccelerator` | Done |
| Upgrade of a generated project | `-Upgrade`, with Git as the merge tool (see the [upgrade guide](../upgrade-guide.md)) | Done |
| Plan then approve for the bootstrap | `-Deploy` plans first; `-AutoApprove` skips the prompt | Done |
| Grant roles helper | `Grant-MLOpsStorageAccess`; other role prerequisites are documented in [Azure subscriptions and permissions](../prerequisites/azure.md) | Partly done |
| Community files and release packaging | README, CONTRIBUTING, SECURITY, SUPPORT, code of conduct and a `release.yml` that builds a zip on each `v*` tag | Done |
| Pin checks | `Test-MLOpsAcceleratorVersion` and `Update-MLOpsAcceleratorVersion` | Done |
| Publish to the PowerShell Gallery | The module is pre-release `v0.2.0`, tagged but not yet published. Waiting on the `PSGALLERY_API_KEY` secret ([issue 35](https://github.com/pgabriel-01/mlops-v3/issues/35)) | Open |
| End-to-end tests against real Azure | The `e2e.yml` workflow applies, verifies and destroys scenarios 1 to 12 on Terraform and Bicep. The GitHub and Azure DevOps bootstraps and the Bicep pipeline on both are also verified live. Not yet tested live: private runners and state storage, endpoint deployment and the `rai` option ([issue 31](https://github.com/pgabriel-01/mlops-v3/issues/31)) | Partly done |
| Azure DevOps Managed DevOps Pools | Not generated ([issue 33](https://github.com/pgabriel-01/mlops-v3/issues/33)) | Open |
| Separate plan and apply identities | One deploy identity today ([issue 32](https://github.com/pgabriel-01/mlops-v3/issues/32)) | Open |
| Wiki | Deferred. `docs/` is the documentation set | Not planned |

## Deliberately not done

Versioned, downloadable template packs with overrides, tfvars-to-JSON conversion, computed region data, HTTP retry options and Terraform version management. The templates ship inside the module, so these add no value yet. Revisit them if the templates move to their own repository.
