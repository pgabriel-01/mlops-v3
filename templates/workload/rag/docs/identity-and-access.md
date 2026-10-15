# Identity and access

The solution uses managed identities and Microsoft Entra ID roles instead of keys. Local authentication is disabled on the AI Services account and on the Azure AI Search service.

The pipeline identity holds the Search Index Data Contributor role to create and fill the index, and the Cognitive Services OpenAI User role to call the models. The Foundry project identity can read the index through the aisearch connection.
