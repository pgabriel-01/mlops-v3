"""Create the search index and load the sample documents with embeddings."""
import sys

from azure.search.documents import SearchClient
from azure.search.documents.indexes import SearchIndexClient
from azure.search.documents.indexes.models import (
    HnswAlgorithmConfiguration,
    SearchableField,
    SearchField,
    SearchFieldDataType,
    SearchIndex,
    SimpleField,
    VectorSearch,
    VectorSearchProfile,
)

import os

from rag import EMBEDDING_DIM, INDEX_NAME, credential, embed, load_chunks, openai_client


def build_index():
    return SearchIndex(
        name=INDEX_NAME,
        fields=[
            SimpleField(name="id", type=SearchFieldDataType.String, key=True),
            SimpleField(name="source", type=SearchFieldDataType.String, filterable=True),
            SearchableField(name="content", type=SearchFieldDataType.String),
            SearchField(
                name="embedding",
                type=SearchFieldDataType.Collection(SearchFieldDataType.Single),
                searchable=True,
                vector_search_dimensions=EMBEDDING_DIM,
                vector_search_profile_name="hnsw",
            ),
        ],
        vector_search=VectorSearch(
            algorithms=[HnswAlgorithmConfiguration(name="hnsw-config")],
            profiles=[VectorSearchProfile(name="hnsw", algorithm_configuration_name="hnsw-config")],
        ),
    )


def main(docs_dir="docs"):
    endpoint = os.environ["SEARCH_ENDPOINT"]
    SearchIndexClient(endpoint, credential()).create_or_update_index(build_index())
    chunks = load_chunks(docs_dir)
    vectors = embed(openai_client(), [c["content"] for c in chunks])
    for chunk, vec in zip(chunks, vectors):
        chunk["embedding"] = vec
    result = SearchClient(endpoint, INDEX_NAME, credential()).upload_documents(chunks)
    failed = [r for r in result if not r.succeeded]
    if failed:
        raise SystemExit(f"{len(failed)} documents failed to upload")
    print(f"Indexed {len(chunks)} chunks into {INDEX_NAME}")


if __name__ == "__main__":
    main(*sys.argv[1:])
