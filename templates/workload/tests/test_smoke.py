"""End-to-end smoke test of prep, train and evaluate on a data sample."""

import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"


def run(script, *args, env):
    subprocess.run([sys.executable, str(SRC / script), *map(str, args)], check=True, env=env, cwd=SRC)


@pytest.mark.parametrize("asset", ["taxi-csv", "taxi-parquet"])
def test_pipeline_steps(tmp_path, asset):
    sample = ROOT / "data" / asset
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
