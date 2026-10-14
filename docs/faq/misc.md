---
title: "Miscellaneous"
weight: 4
---

## Has this been applied to live Azure?

Partly. See [known issues](../known-issues.md) for what has and has not been deployed.

## Can I train a model in the tests?

The accelerator's own tests never train a model; they render, validate and plan only. Training runs in your generated `ml-train` pipeline.

## Which Azure Verified Modules versions are used?

The ones pinned in `versions.lock.json`. See [Azure Verified Modules](../reference/azure-verified-modules.md).

## How do I report a bug or contribute?

Open an issue or pull request in the repository. See `CONTRIBUTING.md`.
