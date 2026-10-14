---
title: "12 - Policy mode"
weight: 12
---

```yaml
policy_mode: audit   # audit | deny | none
```

Built-in Azure Policy guardrails on each environment resource group.

- `audit` (default): report non-compliance only.
- `deny`: block non-compliant changes. Try it in `dev` first.
- `none`: assign nothing. This is the default for scenario 11, where the platform team owns policy.

See [Azure Policy](../policy/_index.md) for the policies, the reasoning and the FAQ.

Back to [Options](_index.md).
