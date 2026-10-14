"""Split raw tabular data into train/val/test parquet datasets."""

import argparse
from pathlib import Path

import mlflow
import numpy as np
import pandas as pd
import yaml

from common import FEATURE_COLS, TARGET_COL


def parse_args():
    parser = argparse.ArgumentParser("prep")
    parser.add_argument("--raw_data", required=True)
    parser.add_argument("--train_data", required=True)
    parser.add_argument("--val_data", required=True)
    parser.add_argument("--test_data", required=True)
    parser.add_argument("--seed", type=int, default=0)
    return parser.parse_args()


def read_mltable_folder(folder: Path) -> pd.DataFrame:
    # Parses the MLTable file directly so the job does not need the mltable package,
    # which does not yet support the Python version this accelerator pins.
    spec = yaml.safe_load((folder / "MLTable").read_text())
    frames = [read_raw(folder / Path(p["file"])) for p in spec["paths"] if "file" in p]
    if not frames:
        raise ValueError(f"MLTable in {folder} has no local file paths")
    return pd.concat(frames, ignore_index=True)


def read_raw(path: Path) -> pd.DataFrame:
    if path.is_dir() and (path / "MLTable").exists():
        return read_mltable_folder(path)
    if path.is_dir():
        files = sorted(path.glob("*.parquet")) + sorted(path.glob("*.csv"))
        if not files:
            raise FileNotFoundError(f"No parquet/csv files under {path}")
        path = files[0]
    if path.suffix == ".parquet":
        return pd.read_parquet(path)
    return pd.read_csv(path)


def main(args):
    data = read_raw(Path(args.raw_data))[FEATURE_COLS + [TARGET_COL]]

    rng = np.random.default_rng(args.seed)
    draw = rng.random(len(data))
    splits = {
        "train": (data[draw < 0.7], args.train_data),
        "val": (data[(draw >= 0.7) & (draw < 0.85)], args.val_data),
        "test": (data[draw >= 0.85], args.test_data),
    }
    for name, (frame, out_dir) in splits.items():
        mlflow.log_metric(f"{name}_size", frame.shape[0])
        frame.to_parquet(Path(out_dir) / f"{name}.parquet")


if __name__ == "__main__":
    with mlflow.start_run():
        main(parse_args())
