---
title: "13 - CSV or parquet"
weight: 13
---

Choose the bundled sample format with `data_source`:

```yaml
data_source: taxi-parquet   # or taxi-csv (default)
```

`taxi-csv` and `taxi-parquet` hold the same NYC taxi rows and register as MLTable data assets, so the pipeline code is identical.

For real parquet, set `data_source: nyc-taxi-open`. It is a 2,000-row sample of the public [Azure Open Datasets yellow taxi data](https://learn.microsoft.com/azure/open-datasets/dataset-taxi-yellow) (January 2015) with its original column names such as `tpepPickupDateTime` and `fareAmount`. `prep.py` cleans it and maps it to the model features. To train on more rows, copy parquet files from `https://azureopendatastorage.blob.core.windows.net/nyctlc/yellow/` (anonymous read) into your ADLS container and read them with the `adls` source.

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

The `adls` source registers one file as a `uri_file`, not an MLTable (see [Known issues](../known-issues.md)). `prep.py` reads parquet or CSV, and applies the Open Datasets mapping when it sees those column names.

Back to [Options](_index.md).
