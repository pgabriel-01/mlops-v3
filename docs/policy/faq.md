---
title: "Policy FAQ and tips"
weight: 3
---

Common questions about the policy guardrails.

- **A deployment failed with `RequestDisallowedByPolicy`.** Check the mode. In `deny` mode, find the failing assignment in the activity log, fix the resource, or switch to `audit`.
- **Policy shows non-compliant straight after deployment.** Compliance evaluation can take up to about 30 minutes; trigger a scan with `az policy state trigger-scan`.
- **I already have tenant-wide policy.** Use `policy_mode: none` and let your own assignments apply. Check them against the [assignments](assignments.md) first.
- **Can I add more?** Add an entry to the `policies` map in `infra/policy.tf` (Terraform) or the `policies` array in `infra/workload.bicep` (Bicep). Browse built-ins in [AzAdvertizer](https://www.azadvertizer.net/azpolicyadvertizer_all.html) or the [Learn built-in list](https://learn.microsoft.com/azure/machine-learning/policy-reference).
- **Preview policies.** The accelerator does not assign preview policies.

## Not applied to live Azure yet

The assignments are validated offline (render, `terraform validate`, `az bicep build`). They have not been applied to a subscription.
