# Sample data notice

The `taxi-csv` and `taxi-parquet` sample data sets are derived from the 9,773 rows of `transformed_data.csv` in the NYC taxi regression example in the Azure Machine Learning examples repository (`cli/jobs/pipelines-with-components/nyc_taxi_data_regression` in https://github.com/Azure/azureml-examples). The redundant `Unnamed: 0` index column was removed, and the `taxi-parquet` copy is the same table converted to Parquet.

That repository is distributed under the MIT License:

MIT License

Copyright (c) Microsoft Corporation.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## nyc-taxi-open

The `nyc-taxi-open` sample is 2,000 randomly selected, cleaned rows (seed 0) from the January 2015 yellow taxi partition of the Azure Open Datasets `nyctlc` data set (`https://azureopendatastorage.blob.core.windows.net/nyctlc/yellow/puYear=2015/puMonth=1/`). The trip records are published by the New York City Taxi and Limousine Commission and made available through Azure Open Datasets, see https://learn.microsoft.com/azure/open-datasets/dataset-taxi-yellow. Only the columns the sample needs were kept, with their original names. Check the data set terms before using it beyond this sample.
