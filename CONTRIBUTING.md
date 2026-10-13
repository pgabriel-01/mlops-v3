# Contributing

1. Work on a branch; keep changes focused.
2. Run `Invoke-Pester ./tests` (offline, no model training, no Azure calls). For template changes also run `./tests/Invoke-ScenarioMatrix.ps1 -Quick`; the full matrix (`terraform validate`, `az bicep build`, generated pytest) takes about 16 minutes.
3. Pins live in `versions.lock.json`. Use `Update-MLOpsAcceleratorVersion`, which only bumps Python packages that still resolve together (`pip check`). Record any hold with its reason under `holds`.
4. Infrastructure must use Azure Verified Modules (resource, pattern or utility) where one exists.
5. New scenarios go in `templates/scenarios.json`, with templates, tests and an entry in `docs/scenarios.md`.
6. Never commit secrets. Pipelines use OIDC / workload identity federation.
