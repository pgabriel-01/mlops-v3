---
title: "Azure DevOps"
weight: 4
---

The bootstrap creates a Git repository, an environment per stage, a variable group per environment, and an Azure Resource Manager service connection per environment that uses workload identity federation. The Azure DevOps **project** must already exist.

## Organisation and project

- Know your organisation URL (`azdo_org_url`, e.g. `https://dev.azure.com/my-org`) and an existing project (`azdo_project`).
- The organisation must be connected to the same Microsoft Entra tenant as the Azure subscription.
- Enable the Git repos, Pipelines and Environments features in the project.

## Personal access token

Create a PAT and expose it as `AZDO_PERSONAL_ACCESS_TOKEN`. Scopes (or equivalent permissions):

- Project and Team: Read
- Code: Read & write, Full
- Build: Read & execute
- Environment: Read & manage
- Service Connections: Read, query & manage
- Variable Groups: Read, create & manage

The user that owns the PAT needs rights to create service connections and repositories in the project.

```powershell
$env:AZDO_PERSONAL_ACCESS_TOKEN = '<pat>'
```

## Approvals

Approvals and checks on the environments are not configured by the bootstrap. Add approvers on the `test` and `prod` environments.

## Pipelines

The bootstrap does not register the pipelines. After pushing the generated repo, create pipelines from the YAML files in `pipelines/` (names are up to you; the generated README lists the order: infra, ml-train, ml-deploy, ml-promote).
