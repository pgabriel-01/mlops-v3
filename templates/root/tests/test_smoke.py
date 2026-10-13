"""End-to-end smoke test of prep -> train -> evaluate on a data sample."""

import json
import os
import subprocess
import sys
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"


def run(script, *args, env):
    subprocess.run([sys.executable, str(SRC / script), *map(str, args)], check=True, env=env, cwd=SRC)


def test_pipeline_steps(tmp_path):
    sample = tmp_path / "sample.csv"
    pd.read_csv(ROOT / "data" / "taxi-data.csv").head(2000).to_csv(sample, index=False)
    dirs = {n: tmp_path / n for n in ("train", "val", "test", "model", "eval")}
    for d in dirs.values():
        d.mkdir()
    env = {**os.environ, "MLFLOW_TRACKING_URI": f"sqlite:///{tmp_path / 'mlflow.db'}", "MLFLOW_DISABLE_AGENT_HINT": "1"}

    run("prep.py", "--raw_data", sample, "--train_data", dirs["train"], "--val_data", dirs["val"], "--test_data", dirs["test"], env=env)
    run("train.py", "--train_data", dirs["train"], "--model_output", dirs["model"] / "m", "--n_estimators", 20, env=env)
    run("evaluate.py", "--model_name", "smoke", "--model_input", dirs["model"] / "m", "--test_data", dirs["test"], "--evaluation_output", dirs["eval"], env=env)

    metrics = json.loads((dirs["eval"] / "metrics.json").read_text())
    assert metrics["test_r2"] > 0.5
    assert metrics["deploy_flag"] is True
