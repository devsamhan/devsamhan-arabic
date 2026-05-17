"""
Fixture-driven behavioral tests for chunk_semantic().
Phase 2C — covers chunking.json cases only.
"""

import json
import pathlib

import pytest

from devsamhan_arabic_text_pipeline import chunk_semantic

FIXTURES_DIR = pathlib.Path(__file__).parent.parent.parent / "test_fixtures"

_VALID_TYPES = {"book", "chapter", "section", "topic", "subtopic", "paragraph"}


def _load_cases(filename: str) -> list[dict]:
    with (FIXTURES_DIR / filename).open(encoding="utf-8") as f:
        return json.load(f)["cases"]


_CHUNKING_CASES = _load_cases("chunking.json")


# ---------------------------------------------------------------------------
# Fixture-driven parametrised tests
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("case", _CHUNKING_CASES, ids=[c["id"] for c in _CHUNKING_CASES])
def test_chunking_fixture(case):
    text = case["input"]
    result = chunk_semantic(text)
    exp = case["expected"]

    # chunk count
    assert len(result) == exp["chunk_count"], (
        f"[{case['id']}] chunk_count={len(result)}, expected={exp['chunk_count']}; "
        f"titles={[c.get('title') for c in result]}"
    )

    # per-chunk checks from fixture
    for i, exp_chunk in enumerate(exp.get("chunks", [])):
        res_chunk = result[i]

        if "title" in exp_chunk:
            assert res_chunk["title"] == exp_chunk["title"], (
                f"[{case['id']}] chunk[{i}] title={res_chunk['title']!r}, "
                f"expected={exp_chunk['title']!r}"
            )

        if "type" in exp_chunk:
            assert res_chunk["type"] == exp_chunk["type"], (
                f"[{case['id']}] chunk[{i}] type={res_chunk['type']!r}, "
                f"expected={exp_chunk['type']!r}"
            )

        if "start_index" in exp_chunk:
            assert res_chunk["start_index"] == exp_chunk["start_index"], (
                f"[{case['id']}] chunk[{i}] start_index={res_chunk['start_index']}, "
                f"expected={exp_chunk['start_index']}"
            )

    # structural validity for every returned chunk
    for i, chunk in enumerate(result):
        # required fields present
        for field in ("title", "type", "text", "start_index", "end_index"):
            assert field in chunk, (
                f"[{case['id']}] chunk[{i}] missing field {field!r}"
            )

        # type is valid
        assert chunk["type"] in _VALID_TYPES, (
            f"[{case['id']}] chunk[{i}] invalid type {chunk['type']!r}"
        )

        # indices are valid
        si, ei = chunk["start_index"], chunk["end_index"]
        assert 0 <= si < ei <= len(text), (
            f"[{case['id']}] chunk[{i}] invalid indices [{si}:{ei}] for text len={len(text)}"
        )

        # text matches original span
        assert chunk["text"] == text[si:ei], (
            f"[{case['id']}] chunk[{i}] text != input[start_index:end_index]"
        )

        # no empty chunks
        assert chunk["text"].strip(), (
            f"[{case['id']}] chunk[{i}] text is empty or whitespace-only"
        )


# ---------------------------------------------------------------------------
# Focused unit tests
# ---------------------------------------------------------------------------

class TestChunkingFocused:
    def test_empty_input_returns_empty_list(self):
        assert chunk_semantic("") == []

    def test_whitespace_only_returns_empty_list(self):
        assert chunk_semantic("   \n\t  ") == []

    def test_plain_paragraph_returns_one_paragraph_chunk(self):
        text = "العقد شريعة المتعاقدين، ولا يجوز نقضه إلا باتفاق الطرفين."
        result = chunk_semantic(text)
        assert len(result) == 1
        assert result[0]["type"] == "paragraph"
        assert result[0]["title"] is None

    def test_heading_text_preserved_in_title(self):
        text = "الباب الأول: في العقود\nمحتوى الباب."
        result = chunk_semantic(text)
        assert result[0]["title"] == "الباب الأول: في العقود"

    def test_indices_point_to_exact_original_substring(self):
        text = "الفصل الأول: في الأركان\nالأركان ثلاثة."
        result = chunk_semantic(text)
        assert len(result) == 1
        chunk = result[0]
        assert text[chunk["start_index"]:chunk["end_index"]] == chunk["text"]

    def test_start_index_zero_for_first_heading(self):
        text = "الباب الثاني: في الشروط\nشروط الصحة."
        result = chunk_semantic(text)
        assert result[0]["start_index"] == 0

    def test_input_not_mutated(self):
        text = "الفصل الأول\nالمحتوى."
        snapshot = text[:]
        chunk_semantic(text)
        assert text == snapshot

    def test_no_empty_chunks_returned(self):
        text = "الباب الأول: في العقود\nمحتوى.\n\nالباب الثاني: في الشروط\nمحتوى."
        result = chunk_semantic(text)
        for chunk in result:
            assert chunk["text"].strip()

    def test_paragraph_title_is_none(self):
        text = "فقرة أولى.\n\nفقرة ثانية."
        result = chunk_semantic(text)
        for chunk in result:
            assert chunk["title"] is None

    def test_chunk_semantic_importable(self):
        from devsamhan_arabic_text_pipeline import chunk_semantic as cs
        assert callable(cs)
