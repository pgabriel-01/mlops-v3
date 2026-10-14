---
title: "4 - Your own data (ADLS)"
weight: 4
---

# Your own data (ADLS)

```yaml
data_source: adls
adls:
  account_name: stcontosodata
  container: raw
  path: taxi/trips.csv      # a CSV with the same columns as the taxi sample
```

The datastore uses identity-based access; grant the workspace identity **Storage Blob Data Reader** (`Grant-MLOpsStorageAccess` does this). Snowflake and Azure SQL: land the data in ADLS first, see [data sources](../data-sources.md).

Back to [Options](index.md).
