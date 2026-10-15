from rag import chunk_text, load_chunks


def test_chunk_text_respects_size():
    text = "\n\n".join(["a" * 300] * 5)
    chunks = chunk_text(text, size=700)
    assert len(chunks) == 3
    assert all(len(c) <= 700 for c in chunks)


def test_load_chunks_reads_pdf_and_markdown_samples():
    chunks = load_chunks("docs")
    sources = {c["source"] for c in chunks}
    assert {"employee_handbook.pdf", "PerksPlus.pdf", "Zava_Company_Overview.md"} <= sources
    assert all({"id", "source", "content"} <= set(c) for c in chunks)
