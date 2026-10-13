"""Register the model when the evaluation step approved it."""

import argparse
import json
from pathlib import Path

import mlflow


def parse_args():
    parser = argparse.ArgumentParser("register")
    parser.add_argument("--model_name", required=True)
    parser.add_argument("--model_path", required=True)
    parser.add_argument("--evaluation_output", required=True)
    parser.add_argument("--model_info_output_path", required=True)
    return parser.parse_args()


def main(args):
    metrics = json.loads((Path(args.evaluation_output) / "metrics.json").read_text())
    info = {"registered": False}

    if metrics["deploy_flag"]:
        with mlflow.start_run():
            mlflow.log_artifacts(args.model_path, artifact_path="model")
            run_id = mlflow.active_run().info.run_id
            version = mlflow.register_model(f"runs:/{run_id}/model", args.model_name)
            client = mlflow.MlflowClient()
            client.set_model_version_tag(args.model_name, version.version, "test_rmse", str(metrics["test_rmse"]))
        info = {"registered": True, "name": args.model_name, "version": version.version}
    else:
        print("Model did not improve on the registered version; skipping registration.")

    (Path(args.model_info_output_path) / "model_info.json").write_text(json.dumps(info))


if __name__ == "__main__":
    main(parse_args())
