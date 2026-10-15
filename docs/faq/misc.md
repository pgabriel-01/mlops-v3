---
title: "Miscellaneous"
weight: 4
---

## Has this been applied to live Azure?

Partly. All 11 scenarios are applied live on Terraform and Bicep. The bootstrap apply, private runners, Azure DevOps and endpoint deployment are not verified live. See [known issues](../known-issues.md#live-deployment-coverage).

## Can I train a model in the tests?

The accelerator's own tests never train a model; they render, validate and plan only. Training runs in your generated `ml-train` pipeline.

## Which Azure Verified Modules versions are used?

The ones pinned in `versions.lock.json`. See [Azure Verified Modules](../reference/azure-verified-modules.md).

## How do I report a bug or contribute?

Open an issue or pull request in the repository. See `CONTRIBUTING.md`.
