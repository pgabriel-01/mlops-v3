# Azure Verified Modules

Infra and bootstrap use AVM **resource** modules (`Azure/avm-res-*`, `br/public:avm/res/*`) and **utility** modules
(`avm-utl-regions`, `Azure/naming`). Pattern modules are used only where one fits (AI Foundry); no AVM pattern covers a
plain Azure ML workspace. AVM telemetry is on by default; set `enable_telemetry = false` (Terraform) or
`enableTelemetry = false` (Bicep) to disable it. Exact versions are in `versions.lock.json`.
