---
title: Release notes
weight: 4
---

This page lists only **breaking changes**, the ones that need action when you [upgrade](upgrade-guide.md). Everything else is in [What's new](whats-new.md).

There is no tagged release yet, so the entries below are changes to the pre-release that affect projects you generated earlier. After the first tag, each entry will link to its GitHub release.

## Unreleased

### Policy guardrails assigned by default

New projects get built-in Azure Policy assignments in `audit` mode (`none` for `existing-platform`). Set `policy_mode` to choose; see [Policy mode](options/12-policy-mode.md).

**Action for existing projects:**
- Re-run the bootstrap. The deploy identity now needs **Resource Policy Contributor**, because Contributor cannot write policy assignments.
- Or set `policy_mode: none` to keep the old behavior.

### Compute clusters have local authentication disabled

Compute clusters are generated with local auth off (`local_auth_enabled = false` in Terraform, `disableLocalAuth: true` in Bicep), to satisfy the "ML computes should have local auth disabled" policy. Access uses Microsoft Entra ID only.

**Action:** if you rely on keys or SSH credentials for the cluster, change the generated setting before you deploy. Expect the cluster to be updated or replaced on the next apply, so check the plan.

### Governance policy assignment moved

The single governance-only policy assignment was replaced by the `policy.tf` / `policyMode` guardrails. They apply to every scenario, not only governance ones. The `governance` flag still controls budget, locks and diagnostics.

**Action:** check the Terraform plan. The old assignment is destroyed and the new ones are created.
