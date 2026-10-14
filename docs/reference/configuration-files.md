---
title: Configuration files
weight: 72
---

The accelerator has **one input** and several **generated** files. This is simpler than ALZ, which has separate bootstrap, platform and library files.

## Inputs file

`inputs.yaml` (or `inputs.json`) is the only file you write. It is validated against `schema/inputs.schema.json` before anything is generated.

- Create one for a scenario with `New-MLOpsInputFile -Scenario <name> -Path inputs.yaml`.
- Start from `inputs.example.yaml`, which lists every input with comments.
- All inputs are documented in [Options](../options/_index.md); the scenario list is in [Scenarios](../scenarios/_index.md).

{{% callout style="note" title="YAML or JSON" %}}
If you can't install the `powershell-yaml` module, use a `.json` file with the same keys. Files ending in `.json` are read as JSON, anything else as YAML. Finish your edits in YAML, then convert.
{{% /callout %}}

## Generated files

You do not edit these during bootstrap. Afterwards they belong to your repository.

| Path | What it is | Edit it? |
|---|---|---|
| `bootstrap/` | Terraform that creates the repo, environments, identity, state storage and Actions variables. Always Terraform. | No, re-run instead |
| `infra/` | Terraform or Bicep for the workload, with one `envs/<env>` file per environment | Yes, to tune sizes, tags and settings |
| `infra/envs/<env>.tfvars` / `.bicepparam` | Per-environment values, such as `policy_mode` and budgets | Yes |
| `.github/workflows/` or `azure-pipelines/` | CI/CD for deploy, train and promote | Yes |
| `src/` and the workload files | The ML pipeline and sample code | Yes, this is your code |
| `.mlops-v3/generation.json` | Records the inputs and module version used to generate the project | No |
| `.mlops-v3/versions.lock.json` | The tool and module versions used | No |

Bootstrap also feeds shared values (subscription, location, project name) into the environment files, so you only enter them once.

## Upgrading

`Deploy-MLOpsAccelerator -Upgrade` regenerates into an existing project (marked by `.mlops-v3/`) and **overwrites** files. Commit first and review the diff, so you keep your own edits. See [Run](../run.md).

## What we don't have

ALZ's separate platform file and `lib` folder (management groups and policy libraries) have no equivalent here. Policy is limited to [built-in guardrails](../policy/_index.md), and management groups are out of scope.
