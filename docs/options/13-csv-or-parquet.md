---
title: "13 - CSV or parquet"
weight: 13
---

Choose the bundled sample format with `data_source`:

```yaml
data_source: taxi-parquet   # or taxi-csv (default)
```

Both samples hold the same NYC taxi rows and register as MLTable data assets, so the pipeline code is identical.

## Why parquet

- **Typed columns.** Parquet stores the data type of each column. CSV is plain text, so every reader has to guess types.
- **Smaller and faster.** Parquet is compressed and column based, so a job reads only the columns it needs. The same table is usually several times smaller than the CSV.
- **The usual format for real data.** Data lakes, Fabric, Synapse and Azure Open Datasets all use it.

CSV stays the default because everyone can open it in a text editor. Start there, then switch once you are comfortable.

## Convert a CSV to parquet

```python
import pandas as pd

pd.read_csv("taxi-data.csv").to_parquet("taxi-data.parquet", index=False)
```

## Using your own parquet

The `adls` source currently expects a CSV and registers it as a single file, not an MLTable (see [Known issues](../known-issues.md)). Reading your own parquet from ADLS and a parquet source from Azure Open Datasets are tracked in issues 57 and 61.

Back to [Options](_index.md).
