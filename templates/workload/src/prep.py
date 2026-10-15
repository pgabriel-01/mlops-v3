"""Split raw tabular data into train, validation and test Parquet datasets."""

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


def normalize_open_dataset(raw: pd.DataFrame) -> pd.DataFrame:
    """Map Azure Open Datasets NYC yellow taxi columns (2015 and earlier) to the sample schema."""
    pickup = pd.to_datetime(raw["tpepPickupDateTime"])
    dropoff = pd.to_datetime(raw["tpepDropoffDateTime"])
    out = pd.DataFrame(
        {
            "cost": raw["fareAmount"],
            "distance": raw["tripDistance"],
            "dropoff_latitude": raw["endLat"],
            "dropoff_longitude": raw["endLon"],
            "passengers": raw["passengerCount"],
            "pickup_latitude": raw["startLat"],
            "pickup_longitude": raw["startLon"],
            "store_forward": (raw["storeAndFwdFlag"] == "Y").astype(int),
            "vendor": pd.to_numeric(raw["vendorID"], errors="coerce").fillna(0).astype(int),
        }
    )
    for prefix, ts in (("pickup", pickup), ("dropoff", dropoff)):
        out[f"{prefix}_weekday"] = ts.dt.weekday
        out[f"{prefix}_month"] = ts.dt.month
        out[f"{prefix}_monthday"] = ts.dt.day
        out[f"{prefix}_hour"] = ts.dt.hour
        out[f"{prefix}_minute"] = ts.dt.minute
        out[f"{prefix}_second"] = ts.dt.second
    valid = (
        (out["cost"] > 0)
        & (out["distance"] > 0)
        & (out["passengers"] > 0)
        & out["pickup_latitude"].between(40, 41)
        & out["dropoff_latitude"].between(40, 41)
        & out["pickup_longitude"].between(-75, -73)
        & out["dropoff_longitude"].between(-75, -73)
    )
    return out[valid].reset_index(drop=True)


def main(args):
    raw = read_raw(Path(args.raw_data))
    if "tpepPickupDateTime" in raw.columns:
        raw = normalize_open_dataset(raw)
    data = raw[FEATURE_COLS + [TARGET_COL]]

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
