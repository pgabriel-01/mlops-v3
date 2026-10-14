---
title: "Azure Verified Modules"
weight: 2
---

Infra and bootstrap use AVM **resource** modules (`Azure/avm-res-*`, `br/public:avm/res/*`) and **utility** modules
(`avm-utl-regions`, `Azure/naming`). Pattern modules are used only where one fits (AI Foundry); no AVM pattern covers a
plain Azure ML workspace. AVM telemetry is on by default; set `enable_telemetry = false` (Terraform) or
`enableTelemetry = false` (Bicep) to disable it. Exact versions are in `versions.lock.json`.

## Finding modules

AVM publishes an [llms.txt](https://azure.github.io/Azure-Verified-Modules/llms.txt) and a machine-readable
[module catalog](https://github.com/Azure/Azure-Verified-Modules/blob/main/docs/static/module-indexes/v1/modules.json)
with the source, status and owners of every Bicep and Terraform module. This site publishes its own [llms.txt](../../llms.txt).
