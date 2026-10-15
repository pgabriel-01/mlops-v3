---
title: "10 - Compute sizes"
weight: 10
---

Set the VM size and the maximum node count in `inputs.yaml`, then regenerate. Check quota for the size in your region first.

```yaml
compute_vm_size: Standard_DS3_v2
compute_max_nodes: 4
```

The training cluster always scales down to 0 nodes. Instance counts for endpoints are not inputs; edit the generated files and commit your change after each `-Upgrade` review:

| What | Setting | Default |
|---|---|---|
| Training cluster | `compute_vm_size` and `compute_max_nodes` | `Standard_DS3_v2`, 0 to 4 nodes |
| Online endpoint | `compute_vm_size` for the size; `instance_count` in `mlops/azureml/online-deployment.yml` | `Standard_DS3_v2`, 1 |
| Batch endpoint | `instance_count` in `mlops/azureml/batch-deployment.yml` | `1` |

Back to [Options](_index.md).
