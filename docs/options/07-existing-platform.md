---
title: "7 - Existing platform"
weight: 7
---

Scenario 11 only. Supply IDs from your platform team; no network, DNS zones or Log Analytics are created:

```yaml
existing_platform:
  subnet_id: /subscriptions/.../subnets/snet-aml
  log_analytics_workspace_id: /subscriptions/.../workspaces/log-platform
  private_dns_zone_ids:
    blob: /subscriptions/.../privateDnsZones/privatelink.blob.core.windows.net
    # file, vault, acr, aml_api, aml_notebooks
```

Back to [Options](_index.md).
