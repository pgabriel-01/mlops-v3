---
title: Upgrade guide
weight: 5
---

How to move an existing project to a newer version of the accelerator. Check the [Release notes](release-notes.md) first for breaking changes.

## Steps

1. Install the new version of the module, then check it: `Get-Module MLOpsAccelerator -ListAvailable`.
2. In your project, create a branch and commit everything. `-Upgrade` overwrites files, so Git is your merge tool.
3. Regenerate into the same folder with your existing inputs:

   ```powershell
   Deploy-MLOpsAccelerator -InputFile inputs.yaml -OutputPath . -Upgrade
   ```

   The folder must contain `.mlops-v3/`, which marks it as a project this tool generated.
4. Review `git diff`. Keep your own changes and take the new template changes.
5. If the release notes say so, re-run the bootstrap (it is idempotent) so new roles and variables are applied.
6. Open a pull request. CI plans the change per environment. Read the plan before approving it.

## Tips

- Keep changes you make to generated files small and in separate commits. This makes the diff after `-Upgrade` easier to read.
- Prefer new inputs over editing generated files when an option exists. See [Options](options/_index.md).
- Upgrade `dev` first and let the plan and tests run before promoting.
- To switch scenario instead, see [Switch scenario](options/11-switch-scenario.md).
