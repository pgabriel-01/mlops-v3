---
title: "Decision flow"
weight: 1
---

Use these flows to reach the values for `inputs.yaml`. The numbers refer to the [planning decisions](_index.md).

## Overall

```mermaid
flowchart TD
    A([Start]) --> B{"Decision 1-2<br/>IaC and CI/CD"}
    B --> C["iac: terraform or bicep<br/>cicd: github or azdo"]
    C --> D{"Decision 3<br/>Scenario"}
    D --> E{"Decision 10<br/>Bootstrap networking"}
    E --> F["Decisions 4-9, 11-13<br/>region, subscription, environments,<br/>data, workloads, repository"]
    F --> G["New-MLOpsInputFile"]
    G --> H["Deploy-MLOpsAccelerator"]
```

## Choose a scenario (decision 3)

```mermaid
flowchart TD
    S([Pick a scenario]) --> N{"Must traffic stay<br/>off the public internet?"}
    N -- No --> P{"What do you need?"}
    P -- Quick trial --> S1["1 basic-public"]
    P -- Batch scoring --> S5["5 batch-scoring"]
    P -- "Safe rollout of online endpoints" --> S6["6 online-bluegreen"]
    P -- Feature store --> S7["7 feature-store"]
    P -- "Promote models across environments" --> S8["8 registry-promotion"]
    P -- Budgets and policy --> S9["9 governance"]
    P -- "Generative AI" --> S10["10 genai-foundry"]
    N -- Yes --> V{"Do you have your own VNet<br/>or a platform landing zone?"}
    V -- "Platform landing zone" --> S11["11 existing-platform"]
    V -- "Own VNet" --> S4["4 byo-vnet"]
    V -- "No, let AML manage it" --> O{"Outbound access"}
    O -- "Open to the internet" --> S2["2 managed-vnet-internet"]
    O -- "Approved destinations only" --> S3["3 managed-vnet-approved"]
```

See the [scenarios](../scenarios/_index.md) page for cost and prerequisites of each.

## Choose the bootstrap networking (decision 10)

```mermaid
flowchart TD
    A([Bootstrap networking]) --> B{"Does policy block public access<br/>to the state storage account?"}
    B -- No --> C{"Use GitHub-hosted runners?"}
    C -- Yes --> D["use_private_networking: false<br/>runner_label: ubuntu-latest"]
    C -- "No, I run my own" --> E["use_private_networking: false<br/>runner_label: your label"]
    B -- Yes --> F{"cicd"}
    F -- github --> G["use_private_networking: true<br/>accelerator deploys VNet, ACI runners<br/>and a private endpoint"]
    F -- azdo --> H["Use your own agent pool<br/>that can reach the private endpoint"]
```

## Choose a version control system (decision 2)

```mermaid
flowchart TD
    A([Where is your code?]) --> B{"Platform"}
    B -- GitHub --> C["cicd: github<br/>github_org, github_repo"]
    B -- "Azure DevOps" --> D["cicd: azdo<br/>azdo_org_url, azdo_project"]
    B -- "Something else" --> E["Use cicd: github or azdo to generate files,<br/>then wire your own pipelines"]
```
