---
title: "Azure Policy"
weight: 65
---

This section documents the Azure Policy guardrails the accelerator assigns to each environment.

{{% callout style="note" %}}
Policy is a guardrail layer, not the main purpose of the accelerator. It uses **built-in** policy definitions only, at **resource group** scope. It does not create custom definitions, initiatives or management-group assignments.
{{% /callout %}}

## Policy mode

Set `policy_mode` in `inputs.yaml`:

| Mode | Effect | Default for |
|---|---|---|
| `audit` | Reports non-compliance; nothing is blocked | All scenarios except 11 |
| `deny` | Blocks non-compliant changes | Opt-in |
| `none` | Assigns nothing | [Scenario 11, existing platform](../scenarios/11-existing-platform.md) (the platform team owns policy) |

Change the value, then run `Deploy-MLOpsAccelerator -Upgrade` and let the infra pipeline apply it.

## Pages

- [Policy assignments](assignments.md): every policy the accelerator assigns, with scope, effect and a definition link.
- [Policy FAQ and tips](faq.md): common problems and how to adjust the guardrails.

## Why only built-in policies?

ALZ ships custom definitions and initiatives because it governs a whole platform and relies on `deployIfNotExists` and `modify` effects. Here the scope is one workload, so built-ins cover it. Custom definitions would add something to version and maintain.

## Why are there no managed identities for policy?

ALZ creates managed identities for `deployIfNotExists` remediation. The accelerator only uses `audit` and `deny` effects, so it needs no remediation identity and no extra role assignments for the identities.

## Prerequisites

Assigning policy needs *Resource Policy Contributor* (Contributor cannot write policy assignments). The bootstrap grants it to the deploy identity at subscription scope. See [Azure prerequisites](../prerequisites/azure.md).
