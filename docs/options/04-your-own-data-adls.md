---
title: "4 - Your own data (ADLS)"
weight: 4
---

```yaml
data_source: adls
adls:
  account_name: stcontosodata
  container: raw
  path: taxi/trips.csv      # a CSV with the same columns as the taxi sample
```

The datastore uses identity-based access; grant the workspace identity **Storage Blob Data Reader** (`Grant-MLOpsStorageAccess` does this). Snowflake and Azure SQL: land the data in ADLS first, see [data sources](../planning/data-sources.md).

The `adls` source registers one file as a `uri_file` data asset, not an MLTable like the bundled samples. MLTable support for ADLS is deferred (see [Known issues](../known-issues.md)).

Back to [Options](_index.md).
