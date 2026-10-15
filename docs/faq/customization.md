---
title: "Customization"
weight: 3
---

## How do I change the generated output?

Prefer an [option](../options/_index.md) in `inputs.yaml` and regenerate. If you edit generated files, keep those changes small and in separate commits so `-Upgrade` diffs stay readable. See the [upgrade guide](../upgrade-guide.md).

## Can I run more than one model?

Yes. Set `workloads: [taxi, churn]`. All workloads share the one platform, and each gets `workloads/<name>/` and its own train and deploy pipelines.

## Can I use separate subscriptions per environment?

Not as an input yet. One subscription hosts all environments. Customize the generated parameter files if you need more.

## Can I add policies?

Yes. Add an entry to the `policies` map in `infra/policy.tf` (Terraform) or the `policies` array in `infra/workload.bicep` (Bicep). See the [policy FAQ](../policy/faq.md).

## Can I change compute sizes or tags?

Yes, with the [compute sizes](../options/10-compute-sizes.md) and [tags](../options/09-tags.md) options.
