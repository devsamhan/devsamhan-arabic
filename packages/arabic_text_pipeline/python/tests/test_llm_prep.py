"""
Fixture-driven behavioral tests for prepare_for_llm().
Phase 2D — covers llm_prep.json cases only.
"""

import json
import pathlib

import pytest

from devsamhan_arabic_text_pipeline import prepare_for_llm

FIXTURES_DIR = pathlib.Path(__file__).parent.parent.parent / "test_fixtures"

_REQUIRED_OUTPUT_FIELDS = {
    "original_text", "clean_text", "quality_report",
    "repair_report", "chunks", "search_key",
    "loose_search_key", "warnings", "metadata",
}


def _load_cases(filename: str) -> list[dict]:
    with (FIXTURES_DIR / filename).open(encoding="utf-8") as f:
        return json.load(f)["cases"]


_LLM_CASES = _load_cases("llm_prep.json")


# ---------------------------------------------------------------------------
# Fixture-driven parametrised tests
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("case", _LLM_CASES, ids=[c["id"] for c in _LLM_CASES])
def test_llm_prep_fixture(case):
    text = case["input"]["text"]
    opts = case["input"].get("options", {})
    result = prepare_for_llm(
        text,
        include_search_key=opts.get("produce_search_key", False),
        include_loose_search_key=opts.get("produce_loose_search_key", False),
    )
    exp = case["expected"]

    # required fields always present
    missing = _REQUIRED_OUTPUT_FIELDS - set(result.keys())
    assert not missing, f"[{case['id']}] result missing fields: {missing}"

    # original_text always preserved
    assert result["original_text"] == text, f"[{case['id']}] original_text was modified"

    # clean_text
    if "clean_text" in exp:
        assert result["clean_text"] == exp["clean_text"], (
            f"[{case['id']}] clean_text mismatch:\n"
            f"  got:      {result['clean_text']!r}\n"
            f"  expected: {exp['clean_text']!r}"
        )

    if exp.get("clean_text_differs_from_original"):
        assert result["clean_text"] != result["original_text"], (
            f"[{case['id']}] clean_text expected to differ from original_text"
        )

    # quality_report
    assert isinstance(result["quality_report"], dict), f"[{case['id']}] quality_report not dict"
    if "quality_report_fields" in exp:
        for field in exp["quality_report_fields"]:
            assert field in result["quality_report"], (
                f"[{case['id']}] quality_report missing field {field!r}"
            )
    if "quality_report" in exp:
        for key, val in exp["quality_report"].items():
            assert result["quality_report"][key] == val, (
                f"[{case['id']}] quality_report[{key!r}]={result['quality_report'][key]!r}, "
                f"expected={val!r}"
            )

    # chunks
    assert isinstance(result["chunks"], list), f"[{case['id']}] chunks not list"
    if exp.get("chunks_present"):
        assert len(result["chunks"]) > 0, f"[{case['id']}] expected non-empty chunks"
    if "chunk_count_min" in exp:
        assert len(result["chunks"]) >= exp["chunk_count_min"], (
            f"[{case['id']}] chunk_count={len(result['chunks'])}, "
            f"expected >= {exp['chunk_count_min']}"
        )

    # search keys
    if "search_key" in exp:
        assert result["search_key"] == exp["search_key"], (
            f"[{case['id']}] search_key={result['search_key']!r}, expected={exp['search_key']!r}"
        )
    if exp.get("search_key_present"):
        assert result["search_key"] is not None, f"[{case['id']}] search_key expected non-None"
    if exp.get("loose_search_key_present"):
        assert result["loose_search_key"] is not None, (
            f"[{case['id']}] loose_search_key expected non-None"
        )

    # warnings — exact list
    if "warnings" in exp:
        assert result["warnings"] == exp["warnings"], (
            f"[{case['id']}] warnings={result['warnings']!r}, expected={exp['warnings']!r}"
        )

    # warnings — containment check
    if "warnings_contain" in exp:
        needle = exp["warnings_contain"]
        assert any(needle in w for w in result["warnings"]), (
            f"[{case['id']}] expected warnings to contain {needle!r}, got {result['warnings']!r}"
        )

    # metadata — required fields
    assert isinstance(result["metadata"], dict), f"[{case['id']}] metadata not dict"
    if "metadata_fields" in exp:
        for field in exp["metadata_fields"]:
            assert field in result["metadata"], (
                f"[{case['id']}] metadata missing field {field!r}"
            )
    if "metadata" in exp:
        for key, val in exp["metadata"].items():
            assert result["metadata"][key] == val, (
                f"[{case['id']}] metadata[{key!r}]={result['metadata'][key]!r}, expected={val!r}"
            )

    # top-level changed (checked via metadata)
    if "changed" in exp:
        assert result["metadata"]["changed"] == exp["changed"], (
            f"[{case['id']}] metadata.changed={result['metadata']['changed']!r}, "
            f"expected={exp['changed']!r}"
        )

    # output_fields
    if "output_fields" in exp:
        for field in exp["output_fields"]:
            assert field in result, f"[{case['id']}] result missing expected field {field!r}"


# ---------------------------------------------------------------------------
# Focused unit tests
# ---------------------------------------------------------------------------

class TestLlmPrepFocused:
    def test_empty_input_creates_warning(self):
        result = prepare_for_llm("")
        assert "empty_text" in result["warnings"]

    def test_empty_input_returns_required_fields(self):
        result = prepare_for_llm("")
        for field in _REQUIRED_OUTPUT_FIELDS:
            assert field in result

    def test_apply_repair_false_skips_repair(self):
        text = "مـحـمـد"
        result = prepare_for_llm(text, apply_repair=False)
        assert result["repair_report"] is None
        assert result["clean_text"] == text  # no tatweel removed

    def test_apply_repair_true_uses_repair_text(self):
        text = "مـحـمـد"
        result = prepare_for_llm(text, apply_repair=True)
        assert result["repair_report"] is not None
        assert result["clean_text"] == "محمد"

    def test_chunks_generated_from_clean_text(self):
        text = "الفصل الأول: في العقود\nالعقد هو ارتباط."
        result = prepare_for_llm(text)
        assert len(result["chunks"]) >= 1
        # chunk text must come from clean_text, not original
        clean = result["clean_text"]
        for chunk in result["chunks"]:
            si, ei = chunk["start_index"], chunk["end_index"]
            assert chunk["text"] == clean[si:ei]

    def test_metadata_chunk_count_matches_chunks(self):
        text = "الباب الأول: في العقود\nمحتوى.\n\nالباب الثاني: في الشروط\nمحتوى."
        result = prepare_for_llm(text)
        assert result["metadata"]["chunk_count"] == len(result["chunks"])

    def test_input_not_mutated(self):
        text = "مـحـمـد   بـن   عـبـد   الله"
        snapshot = text[:]
        prepare_for_llm(text)
        assert text == snapshot

    def test_search_key_none_when_not_requested(self):
        result = prepare_for_llm("مرحبا")
        assert result["search_key"] is None
        assert result["loose_search_key"] is None

    def test_search_key_present_when_requested(self):
        result = prepare_for_llm("مرحبا", include_search_key=True)
        assert result["search_key"] is not None
        assert isinstance(result["search_key"], str)

    def test_loose_search_key_present_when_requested(self):
        result = prepare_for_llm("مرحبا", include_loose_search_key=True)
        assert result["loose_search_key"] is not None

    def test_original_text_always_preserved(self):
        text = "مـحـمـد   بـن   عـبـد   الله"
        result = prepare_for_llm(text)
        assert result["original_text"] == text

    def test_metadata_pipeline_version(self):
        result = prepare_for_llm("مرحبا")
        assert result["metadata"]["pipeline_version"] == "0.1.0"
