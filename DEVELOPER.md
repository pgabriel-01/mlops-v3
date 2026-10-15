# Developer guide

- Requirements: PowerShell 7.4+, Pester 5+, `powershell-yaml`, Terraform, Azure CLI with Bicep.
- `make test` runs the Pester suite; `make matrix` renders and validates a quick subset of scenarios (`tests/Invoke-ScenarioMatrix.ps1` runs all 11).
- Files ending in `.tpl` are written without that suffix. Use it for templates that scanners would otherwise read as real files, such as `requirements-dev.txt.tpl`.
- Template tokens use `[[name]]`; add new tokens in `New-MLOpsTokenMap`, then the schema, `inputs.example.yaml`, `docs/options/_index.md` and a test.
- Rendered `.tfvars` and `.tf` must pass `terraform fmt -check`; the scenario matrix checks this in CI.
- Real-Azure tests: `.github/workflows/e2e.yml` (see `docs/known-issues.md`) and `tests/Invoke-E2E.ps1`.
