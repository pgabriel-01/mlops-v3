---
title: "Troubleshooting"
weight: 45
---

| Symptom | Likely cause | What to do |
|---|---|---|
| `terraform init` fails with 403 on the state account | Policy disables public access to storage | Use `use_private_networking: true` or a self-hosted `runner_label`. See [Advanced](advanced.md) |
| Deploy fails with an authorization error on policy | Missing Resource Policy Contributor role | Re-run the bootstrap, or set `policy_mode: none` |
| `RequestDisallowedByPolicy` | `policy_mode: deny` blocked a resource | Check the activity log, fix the resource, or use `audit` |
| Name conflict on Key Vault or workspace | Soft-deleted resources hold the name | Purge them, or set a new `name_suffix` |
| Jobs never start and the message mentions payments or spending limit | GitHub Actions minutes or budget exhausted | Check Billing, or use self-hosted runners |
| Pipelines missing in Azure DevOps | Bootstrap does not register pipelines | Create them from the YAML in `pipelines/` |
| Private scenario `ml-train` cannot reach the workspace | Hosted agents have no network path | Use a self-hosted runner or agent in a network that reaches the private endpoints |
| Compliance shows non-compliant right after deploy | Evaluation delay of up to about 30 minutes | `az policy state trigger-scan` |

More detail: [known issues](known-issues.md) and the [FAQ](faq/_index.md).
