---
title: "3 - GitHub or Azure DevOps"
weight: 3
---

```yaml
cicd: github
github_org: contoso
github_repo: mlops-demo
# or
cicd: azdo
azdo_org_url: https://dev.azure.com/contoso
azdo_project: mlops
```

Azure DevOps pipelines are generated under `pipelines/` and must be registered manually (see [Run](../run.md)).

Back to [Options](_index.md).
