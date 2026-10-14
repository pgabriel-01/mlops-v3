# Copilot instructions for mlops-v3

PowerShell module `Deploy-MLOpsAccelerator` (`src/MLOpsAccelerator`) that renders bootstrap, IaC (Terraform or Bicep on Azure Verified Modules), CI/CD (GitHub or Azure DevOps) and an Azure ML workload from one inputs file, across 11 scenarios.

## Layout

- `src/MLOpsAccelerator/`: the module. `schema/inputs.schema.json` validates inputs.
- `templates/`: everything that gets rendered. `manifest.json` maps sources to destinations (`when` is an equality check); `scenarios.json` defines the 11 scenarios. Tokens are `[[token]]` and `[[#each_env]]`.
- `docs/`: the Hugo content (theme vendored in `site/themes/relearn`). Section pages are `_index.md`; order comes from front matter `weight`.
- `tests/`: Pester tests and the scenario matrix.
- `versions.lock.json`: pins. Record any hold with its reason.

## Rules

- Tests are offline. Never train a model in tests and never call Azure from them.
- Write files as UTF-8, LF, no BOM. The code must run on Windows, macOS and Linux (use `Join-Path`, no bash-only syntax in the module).
- Use the latest compatible libraries and AVM modules. Do not bump a held pin (`azurerm` below 5.0, `pyarrow` below 26, `azureml-mlflow` 1.60.0) without reading its reason.
- Policy is built-in Azure Policy only, at resource-group scope, effects `audit` or `deny`. No custom definitions and no DINE.
- Docs use Hugo Relearn shortcodes (`{{% callout %}}`, `{{< tabs >}}`), not MkDocs admonitions. Update `docs/whats-new.md`, and `docs/release-notes.md` for breaking changes.
- Be honest about what is unverified: nothing has been applied to live Azure yet.

## Validate

```powershell
Invoke-Pester ./tests                                   # offline, about a minute
./tests/Invoke-ScenarioMatrix.ps1 -Quick                # after template changes
./tests/Invoke-ScenarioMatrix.ps1 -Scenario basic-public -Iac terraform   # one scenario
cd site; hugo --minify                                  # docs must build with no warnings
```

The full matrix takes about 16 minutes. `terraform fmt` must be clean on rendered output.
