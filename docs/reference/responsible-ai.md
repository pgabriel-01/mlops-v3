---
title: "Responsible AI"
weight: 70
---

The accelerator does not yet automate Responsible AI (RAI) controls. This page lists what is and is not covered, and what is planned.

## What you get today

| Area | Covered by | Notes |
|---|---|---|
| Infrastructure guardrails | [`policy_mode`](../options/12-policy-mode.md) | Private access, no local auth, required tags. Not model behavior. |
| Network isolation, identity, logging | Scenarios 2, 3, 4 and 9 | Security posture, not fairness or safety. |
| Model fairness, explainability, error analysis | Nothing | Bring your own. |
| GenAI content filtering and safety evaluation | Nothing | Scenario 10 deploys AI Foundry without a content filter policy. |

## Planned additions

The plan is an `rai` option, off by default, because RAI applies across scenarios. It is not implemented or verified live.

- Classic ML scenarios: a Responsible AI dashboard step in the training pipeline (fairness, explainability, error analysis) and a model-card template in the repo.
- Scenario 10 (GenAI with AI Foundry): a content filter policy on model deployments, then evaluation runs with the Foundry safety evaluators.

## Until then

- Azure ML: [Responsible AI dashboard](https://learn.microsoft.com/azure/machine-learning/concept-responsible-ai-dashboard) and [model interpretability](https://learn.microsoft.com/azure/machine-learning/how-to-machine-learning-interpretability).
- AI Foundry: [Content filtering](https://learn.microsoft.com/azure/ai-foundry/concepts/content-filtering) and [Risk and safety evaluators](https://learn.microsoft.com/azure/ai-foundry/concepts/evaluation-evaluators/risk-safety-evaluators).
- Add the checks to your own training pipeline under `src/`. The generated CI/CD runs whatever the pipeline produces.

{{% callout style="note" title="Scope" %}}
Tooling does not make a system responsible. The checks above support a review process. They do not replace one.
{{% /callout %}}
