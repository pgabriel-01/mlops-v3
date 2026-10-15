---
title: "GitHub"
weight: 3
---

The bootstrap **creates** the repository (private), its environments (one per environment in your inputs), a deployment branch policy limited to `main`, and the Actions variables the pipelines use to sign in to Azure with OIDC. Nothing needs to exist beforehand except the organization or user account.

## Account and plan

- The `github_org` can be an organization or your username, and you must be allowed to create repositories in it.
- Environments on **private** repositories need a plan that supports them (GitHub Team, Enterprise, or Pro for personal accounts). On the Free plan, create the repository as public or upgrade; otherwise the environment and branch policy resources will fail.
- Required reviewers are **not** configured by the bootstrap. Add reviewers to the `test` and `prod` environments (Settings, Environments) so deployments wait for approval.

## Token

Create a personal access token and expose it as `GITHUB_TOKEN`, or run `gh auth login` and the accelerator reads the token from `gh`.

- Classic token: scope `repo` (full control). The `admin:org` scope is not needed, even for organization repositories.
- Fine-grained token: set the resource owner to the organization, choose **All repositories** or the target repository, and set Repository permissions **Administration**, **Contents**, **Environments**, **Variables** and **Actions** to Read and write, **Metadata** to Read, and Organization permission **Administration** to Read if your organization requires it.
- If the org enforces SSO, authorize the token for it.

```powershell
$env:GITHUB_TOKEN = '<token>'   # or run: gh auth login
```

## After the bootstrap

Push the generated folder to the new repository and merge to `main` to start the pipelines.
