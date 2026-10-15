# Retrieval-augmented generation

Retrieval-augmented generation, or RAG, answers a question by first searching a private document index and then asking a chat model to answer using only the retrieved passages. This keeps answers grounded in your own data and lets you update knowledge without retraining a model.

A RAG system has two parts. Ingestion splits documents into chunks, creates an embedding vector for each chunk and uploads the chunks to a search index. Query time embeds the question, retrieves the closest chunks with vector search and passes them to the chat model as context.
