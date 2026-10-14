---
title: "External data sources (Snowflake, Azure SQL Database)"
weight: 3
---

AML **Import Data (preview)** and **Data Connections (preview)** were retired on 2026-09-30, so the accelerator does not use them.
Microsoft's replacement is Fabric plus an AML datastore ([migration guide](https://learn.microsoft.com/en-us/azure/machine-learning/data-import-migration-guide?view=azureml-api-2)).

Design rule: **AML only consumes a datastore or data asset.** Getting data from Snowflake or Azure SQL into storage is a separate, optional step.

## Options tested

"Tested" means validated offline on 2026-10-13 (no Azure resources were created and no Snowflake account was available). Items marked *docs only* rely on Microsoft documentation.

| # | Option | Result | Evidence |
|---|---|---|---|
| 1 | AML data connection / import (preview) | **Ruled out** | Retired 2026-09-30. The `workspaces/connections` ARM type still exists (Foundry uses it), but import jobs do not. |
| 2 | ADLS Gen2 datastore | **Works** | Bicep (`workspaces/datastores`, `AzureDataLakeGen2`) builds with typed API versions 2024-04-01 to 2025-12-01. Terraform `azurerm_machine_learning_datastore_datalake_gen2` validates. |
| 3 | OneLake datastore | **Works** | Bicep `datastoreType: 'OneLake'` builds. No azurerm resource, so Terraform uses `azapi_resource` (validates). Needs Fabric admin settings and workspace access for the identity (*docs only*). |
| 4 | ADF/Synapse copy pipeline to ADLS Parquet | **Works (IaC)** | azurerm linked services `snowflake` and `azure_sql_database` validate. azurerm has no copy-activity resource, so the pipeline body must be `activities_json`. The pipeline run itself is untested. |
| 5 | Fabric pipeline to OneLake | *Docs only* | 170+ connectors. Needs a Fabric capacity (cost). Fabric items are not managed by AVM, azurerm or Bicep, so this is a prerequisite documented in the README, not generated IaC. |
| 6 | Fabric mirroring | *Docs only* | Azure SQL: needs public network access on the logical server (no private-endpoint-only) and same tenant. Snowflake: username/password or SSO only, no managed identity, preview. |
| 7 | OneLake shortcuts | **Ruled out for these sources** | Only S3 and ADLS Gen2 are supported, not Snowflake or Azure SQL. |
| 8 | Query in the training job | **Works, with constraints** | See below. |

### In-job query details (Python 3.14, full pinned set)

- `snowflake-connector-python` 4.8.0 and `mssql-python` 1.16.0 install alongside the pinned set; `pip check` is clean.
- `pyodbc` is **ruled out**: it needs the system `unixodbc` library and an ODBC driver on the compute image. `mssql-python` bundles its driver.
- Use `fetch_arrow_all()` for Snowflake, not the `[pandas]` extra. That extra requires `pyarrow<24` on Python 3.14, which conflicts with our `pyarrow==25.0.1` pin (mlflow 3.17 caps `pyarrow<26`). The connector only warns when pyarrow 25 is present; the Arrow fetch path still works.
- A query-to-Parquet round trip with pandas and pyarrow works locally (sqlite stand-in). Connection failures surface as clean exceptions.
- Real connections to Snowflake or Azure SQL are untested.
- Credentials must come from Key Vault or managed identity (Azure SQL: Microsoft Entra auth). Never put them in YAML or the repo.
- The query path needs network egress to the source, so private-network scenarios need an approved outbound rule or private endpoint.

## Recommendation

1. Add a `data_source` input: `sample` (default) | `adls` | `onelake` | `snowflake` | `azuresql`.
2. `adls` and `onelake` generate the datastore and data asset (Bicep native, Terraform `azurerm` or `azapi`).
3. `snowflake` and `azuresql` default to **ADF copy to ADLS Parquet** (option 4: Azure-native, no extra capacity, produces the Parquet the next phase needs). Fabric (5 and 6) is documented as the alternative.
4. In-job query (option 8) is opt-in and limited to small data.
