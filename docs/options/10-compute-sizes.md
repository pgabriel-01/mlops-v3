---
title: "10 - Compute sizes"
weight: 10
---

Sizes are not inputs yet. Edit the generated files and keep them out of regeneration by committing your change after each `-Upgrade` review:

| What | File | Default |
|---|---|---|
| Training cluster | `infra/main.tf` (Terraform) or `infra/workload.bicep` (`vm_size`/`vmSize`, max node count) | `Standard_DS3_v2`, 0 to 4 nodes |
| Online endpoint | `mlops/azureml/online-deployment.yml` (`instance_type`, `instance_count`) | `Standard_DS3_v2`, 1 |
| Batch endpoint | `mlops/azureml/batch-deployment.yml` (`instance_count`) | 1 |

Making these inputs is on the to-do list.

Back to [Options](_index.md).
