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


@pytest.mark.parametrize("asset", ["taxi-csv", "taxi-parquet", "nyc-taxi-open"])
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


COMPONENTS = ROOT / "mlops" / "azureml" / "components"


@pytest.mark.parametrize("step", ["prep", "train", "evaluate", "register"])
def test_component_matches_script(step):
    """The component command passes exactly the flags the script defines, and every input and output is declared."""
    import re

    import yaml

    component = yaml.safe_load((COMPONENTS / f"{step}.yml").read_text())
    command = component["command"]
    script = (SRC / f"{step}.py").read_text()
    script_flags = set(re.findall(r'add_argument\("--(\w+)"', script))
    command_flags = set(re.findall(r"--(\w+) \$\{\{", command))
    assert command_flags == script_flags
    for kind in ("inputs", "outputs"):
        used = set(re.findall(rf"\$\{{\{{{kind}\.(\w+)\}}\}}", command))
        assert used == set(component.get(kind, {}))


def test_pipeline_uses_components():
    import yaml

    pipeline = yaml.safe_load((ROOT / "mlops" / "azureml" / "pipeline.yml").read_text())
    names = {yaml.safe_load(p.read_text())["name"] for p in COMPONENTS.glob("*.yml")}
    used = {job["component"].split(":")[1].split("@")[0] for job in pipeline["jobs"].values()}
    assert used == names
