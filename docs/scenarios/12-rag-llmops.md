---
title: "12 - RAG and LLMOps"
weight: 12
---

AI Foundry plus Azure AI Search, a chat and an embedding model, a sample document index, and an evaluation quality gate in the pipeline.

| | |
|---|---|
| Id | `rag-llmops` |
| Network | public |
| Serving | none |
| Adds | Azure AI Search, chat and embedding model deployments, the `aisearch` Foundry connection, a `rag/` workload and a `rag-evaluate` pipeline |
| IaC and CI/CD | Terraform or Bicep; GitHub or Azure DevOps |

Builds on [scenario 10](10-genai-foundry.md). Each environment gets an Azure AI Search service, a chat model and an embedding model deployed on the AI Services account, and an `aisearch` connection on the Foundry project. Local authentication is disabled; access uses managed identities and roles.

The generated `rag/` folder holds a few sample documents, an ingest script that creates a vector index and loads the chunks, and an evaluation script. The `rag-evaluate` pipeline runs the unit tests, builds the index and runs the evaluation questions through retrieval and the chat model. It scores groundedness with the Azure AI evaluation SDK and fails when the average is below `min_groundedness`.

{{% callout style="warning" title="Preview" %}}
This scenario renders and validates offline but has not been applied live yet, and the sample scripts have not run against real models.
{{% /callout %}}

## Use it

```powershell
New-MLOpsInputFile -Scenario rag-llmops -Path inputs.yaml -Iac terraform -Cicd github
```

Optional `rag` section in the inputs file:

```yaml
rag:
  chat_model: gpt-5.4-mini
  chat_model_version: "2026-03-17"
  chat_capacity: 10           # thousands of tokens per minute
  embedding_model: text-embedding-3-small
  embedding_model_version: "1"
  embedding_capacity: 10
  search_sku: basic           # free allows one service per subscription
  min_groundedness: 3.5       # evaluation gate, 1 to 5
```

## Regional quota

Model quota is per subscription, per region and per model, and differs between subscriptions. The defaults use the `GlobalStandard` deployment type, which is offered in the most regions, and a small capacity. Each environment needs its own capacity and its own search service.

Check before you deploy:

```powershell
Test-MLOpsModelQuota -Location swedencentral -Environments 3
```

`Deploy-MLOpsAccelerator -Deploy` runs the same check and stops with the model and region named if quota is short. Request more quota in the Azure portal, choose another region or model, or pass `-SkipRequirementsCheck`. Avoid models that are retiring, such as `gpt-4o-mini` and `gpt-4.1-mini`.

## Limits

- Public network mode only. Private endpoints for Search and the models are defined for the byo-vnet network mode but have not been exercised with this scenario.
- Bicep grants the pipeline identity its data roles through the `DEPLOYER_PRINCIPAL_ID` variable that the generated infrastructure pipeline sets from the signed-in token. If you deploy by hand, set it to your own object id.

## Microsoft documentation

- <https://learn.microsoft.com/azure/ai-foundry/concepts/retrieval-augmented-generation>
- <https://learn.microsoft.com/azure/search/search-what-is-azure-search>
