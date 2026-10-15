"""Shared helpers for the RAG sample: clients, chunking and retrieval."""
import os
from pathlib import Path

from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from azure.search.documents import SearchClient
from azure.search.documents.models import VectorizedQuery
from openai import AzureOpenAI

INDEX_NAME = os.environ.get("SEARCH_INDEX", "docs")
EMBEDDING_DIM = 1536
SCOPE = "https://cognitiveservices.azure.com/.default"


def credential():
    return DefaultAzureCredential()


def openai_client():
    return AzureOpenAI(
        azure_endpoint=os.environ["AI_ENDPOINT"],
        azure_ad_token_provider=get_bearer_token_provider(credential(), SCOPE),
        api_version="2025-04-01-preview",
    )


def search_client():
    return SearchClient(os.environ["SEARCH_ENDPOINT"], INDEX_NAME, credential())


def chunk_text(text, size=800):
    """Split text into chunks on paragraph boundaries, each at most size characters."""
    chunks, current = [], ""
    for para in (p.strip() for p in text.split("\n\n")):
        if not para:
            continue
        if current and len(current) + len(para) + 2 > size:
            chunks.append(current)
            current = para
        else:
            current = f"{current}\n\n{para}" if current else para
    if current:
        chunks.append(current)
    return chunks


def load_chunks(docs_dir):
    out = []
    for path in sorted(Path(docs_dir).glob("*.md")):
        for i, chunk in enumerate(chunk_text(path.read_text(encoding="utf-8"))):
            out.append({"id": f"{path.stem}-{i}", "source": path.name, "content": chunk})
    return out


def embed(client, texts):
    resp = client.embeddings.create(model=os.environ.get("EMBEDDING_DEPLOYMENT", "embedding"), input=texts)
    return [d.embedding for d in resp.data]


def retrieve(question, top=3):
    client = openai_client()
    vector = embed(client, [question])[0]
    results = search_client().search(
        search_text=question,
        vector_queries=[VectorizedQuery(vector=vector, k_nearest_neighbors=top, fields="embedding")],
        top=top,
    )
    return [r["content"] for r in results]


def answer(question):
    """Return the chat answer and the retrieved passages used as context."""
    context = retrieve(question)
    client = openai_client()
    resp = client.chat.completions.create(
        model=os.environ.get("CHAT_DEPLOYMENT", "chat"),
        messages=[
            {"role": "system", "content": "Answer using only the provided context. If the context does not contain the answer, say you do not know."},
            {"role": "user", "content": "Context:\n" + "\n---\n".join(context) + f"\n\nQuestion: {question}"},
        ],
    )
    return resp.choices[0].message.content, "\n".join(context)
