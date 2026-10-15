---
title: "Policy assignments"
weight: 2
---

Policy definitions are built-in, so the accelerator creates no definitions or initiatives. It only assigns them, at resource group scope for each environment. It assigns nothing at management-group or tenant-root scope.

{{% callout style="note" %}}
The table scrolls horizontally on small screens.
{{% /callout %}}

## Default policy assignments

With `policy_mode: none` nothing is assigned. The default is `audit`, except for scenario 11, where the default is `none`.

| Assignment scope | Assignment name | Definition name | Type | Custom or built-in | Effect | Scenarios | Source file | Link | Status |
|---|---|---|---|---|---|---|---|---|---|
| Resource group, every environment | `mlops-<env>-compute-local-auth` | Azure Machine Learning Computes should have local authentication methods disabled | Policy | Built-in | Audit (Deny in `deny` mode) | All except 11 by default | `policy.tf`, `workload.bicep` | [AzAdvertizer](https://www.azadvertizer.net/azpolicyadvertizer/e96a9a5f-07ca-471b-9bc5-6a0f33cbd68f.html) | GA |
| Resource group, every environment | `mlops-<env>-require-project-tag` | Require a tag on resources (`project`) | Policy | Built-in | Deny, enforced only in `deny` mode | All except 11 by default | `policy.tf`, `workload.bicep` | [AzAdvertizer](https://www.azadvertizer.net/azpolicyadvertizer/871b6d14-10aa-478d-b590-94f262ecfa99.html) | GA |
| Resource group, every environment | `mlops-<env>-workspace-no-public-access` | Azure Machine Learning Workspaces should disable public network access | Policy | Built-in | Audit (Deny in `deny` mode) | 2, 3 and 4 (11 only if `policy_mode` is set) | `policy.tf`, `workload.bicep` | [AzAdvertizer](https://www.azadvertizer.net/azpolicyadvertizer/438c38d2-3772-465a-a9cc-7a6666a275ce.html) | GA |

Assignment names are shortened to 64 characters where needed. `enforce` is `true` for the two effect-parameter policies. The tag policy is a fixed `deny`, so audit mode sets `DoNotEnforce`.

## Add your own

Add an entry to the `policies` map in `infra/policy.tf` (Terraform) or the `policies` array in `infra/workload.bicep` (Bicep). Each entry has a definition ID, parameters and an enforcement flag. Browse built-ins in [AzAdvertizer](https://www.azadvertizer.net/azpolicyadvertizer_all.html).

See also [Policy FAQ and tips](faq.md).
