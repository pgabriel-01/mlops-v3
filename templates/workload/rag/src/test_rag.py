from rag import chunk_text, load_chunks


def test_chunk_text_respects_size():
    text = "\n\n".join(["a" * 300] * 5)
    chunks = chunk_text(text, size=700)
    assert len(chunks) == 3
    assert all(len(c) <= 700 for c in chunks)


def test_load_chunks_reads_sample_docs():
    chunks = load_chunks("docs")
    assert chunks and all({"id", "source", "content"} <= set(c) for c in chunks)
