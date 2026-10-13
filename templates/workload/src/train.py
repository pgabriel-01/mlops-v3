"""Train a RandomForestRegressor and save it as an MLflow model."""

import argparse
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import mlflow
import mlflow.sklearn
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, root_mean_squared_error, r2_score

from common import FEATURE_COLS, TARGET_COL


def parse_args():
    parser = argparse.ArgumentParser("train")
    parser.add_argument("--train_data", required=True)
    parser.add_argument("--model_output", required=True)
    parser.add_argument("--n_estimators", type=int, default=300)
    parser.add_argument("--max_depth", type=int, default=10)
    parser.add_argument("--min_samples_leaf", type=int, default=4)
    parser.add_argument("--min_samples_split", type=int, default=5)
    return parser.parse_args()


def main(args):
    train = pd.read_parquet(Path(args.train_data) / "train.parquet")
    x_train, y_train = train[FEATURE_COLS], train[TARGET_COL]

    params = {
        "n_estimators": args.n_estimators,
        "max_depth": args.max_depth,
        "min_samples_leaf": args.min_samples_leaf,
        "min_samples_split": args.min_samples_split,
        "max_features": "sqrt",
        "random_state": 0,
        "n_jobs": -1,
    }
    model = RandomForestRegressor(**params).fit(x_train, y_train)
    mlflow.log_params(params)

    pred = model.predict(x_train)
    mlflow.log_metrics(
        {
            "train_r2": r2_score(y_train, pred),
            "train_rmse": root_mean_squared_error(y_train, pred),
            "train_mae": mean_absolute_error(y_train, pred),
        }
    )

    fig, ax = plt.subplots()
    ax.scatter(y_train, pred, s=4, color="black")
    ax.set_xlabel("Real value")
    ax.set_ylabel("Predicted value")
    mlflow.log_figure(fig, "regression_results.png")
    plt.close(fig)

    # Pip requirements are inferred from the training environment, so the saved
    # model always matches the library versions pinned in the conda file.
    # Models are produced and consumed inside the trusted pipeline, so cloudpickle
    # is used; MLflow 3.x defaults to skops, which rejects sklearn tree types.
    mlflow.sklearn.save_model(
        model,
        path=args.model_output,
        serialization_format="cloudpickle",
        input_example=x_train.head(5),
    )


if __name__ == "__main__":
    with mlflow.start_run():
        main(parse_args())
