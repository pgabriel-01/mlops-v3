"""Evaluate the trained model on the test set and gate promotion on improvement."""

import argparse
import json
from pathlib import Path

import mlflow
import mlflow.sklearn
import pandas as pd
from sklearn.metrics import mean_absolute_error, root_mean_squared_error, r2_score

from common import FEATURE_COLS, TARGET_COL


def parse_args():
    parser = argparse.ArgumentParser("evaluate")
    parser.add_argument("--model_name", required=True)
    parser.add_argument("--model_input", required=True)
    parser.add_argument("--test_data", required=True)
    parser.add_argument("--evaluation_output", required=True)
    return parser.parse_args()


def best_registered_rmse(model_name: str):
    """RMSE of the latest registered model, or None when no model exists yet."""
    client = mlflow.MlflowClient()
    try:
        versions = client.search_model_versions(f"name='{model_name}'")
    except Exception:
        return None
    if not versions:
        return None
    latest = max(versions, key=lambda v: int(v.version))
    value = (latest.tags or {}).get("test_rmse")
    return float(value) if value is not None else None


def main(args):
    test = pd.read_parquet(Path(args.test_data) / "test.parquet")
    model = mlflow.sklearn.load_model(args.model_input)
    pred = model.predict(test[FEATURE_COLS])

    metrics = {
        "test_r2": r2_score(test[TARGET_COL], pred),
        "test_rmse": root_mean_squared_error(test[TARGET_COL], pred),
        "test_mae": mean_absolute_error(test[TARGET_COL], pred),
    }
    mlflow.log_metrics(metrics)

    previous = best_registered_rmse(args.model_name)
    metrics["deploy_flag"] = previous is None or metrics["test_rmse"] <= previous

    out = Path(args.evaluation_output)
    (out / "metrics.json").write_text(json.dumps(metrics, indent=2))
    pd.DataFrame({"actual": test[TARGET_COL], "predicted": pred}).to_parquet(out / "predictions.parquet")


if __name__ == "__main__":
    with mlflow.start_run():
        main(parse_args())
