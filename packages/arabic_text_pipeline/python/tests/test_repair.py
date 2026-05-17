"""
Fixture-driven behavioral tests for repair_text().
Phase 2B — covers repair.json cases only.
"""

import json
import pathlib

import pytest

from devsamhan_arabic_text_pipeline import repair_text

FIXTURES_DIR = pathlib.Path(__file__).parent.parent.parent / "test_fixtures"

_REQUIRED_RESULT_FIELDS = {"original_text", "repaired_text", "changed", "issues_fixed", "suggestions"}


def _load_cases(filename: str) -> list[dict]:
    with (FIXTURES_DIR / filename).open(encoding="utf-8") as f:
        return json.load(f)["cases"]


_REPAIR_CASES = _load_cases("repair.json")


# ---------------------------------------------------------------------------
# Fixture-driven parametrised tests — one test per case in repair.json
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("case", _REPAIR_CASES, ids=[c["id"] for c in _REPAIR_CASES])
def test_repair_fixture(case):
    result = repair_text(case["input"])
    exp = case["expected"]

    # result must have all required fields
    missing = _REQUIRED_RESULT_FIELDS - set(result.keys())
    assert not missing, f"[{case['id']}] result missing fields: {missing}"

    # original_text must be returned unchanged
    assert result["original_text"] == case["input"], (
        f"[{case['id']}] original_text was modified"
    )

    if "repaired_text" in exp:
        assert result["repaired_text"] == exp["repaired_text"], (
            f"[{case['id']}] repaired_text mismatch:\n"
            f"  got:      {result['repaired_text']!r}\n"
            f"  expected: {exp['repaired_text']!r}"
        )

    assert result["changed"] == exp["changed"], (
        f"[{case['id']}] changed={result['changed']!r}, expected={exp['changed']!r}"
    )

    if "issues_fixed" in exp:
        assert result["issues_fixed"] == exp["issues_fixed"], (
            f"[{case['id']}] issues_fixed={result['issues_fixed']!r}, "
            f"expected={exp['issues_fixed']!r}"
        )

    if "suggestions" in exp:
        assert len(result["suggestions"]) == len(exp["suggestions"]), (
            f"[{case['id']}] suggestions count: "
            f"got={len(result['suggestions'])}, expected={len(exp['suggestions'])}"
        )
        for i, (exp_sug, res_sug) in enumerate(
            zip(exp["suggestions"], result["suggestions"])
        ):
            for key, val in exp_sug.items():
                assert res_sug.get(key) == val, (
                    f"[{case['id']}] suggestion[{i}] field {key!r}: "
                    f"got={res_sug.get(key)!r}, expected={val!r}"
                )


# ---------------------------------------------------------------------------
# Focused unit tests
# ---------------------------------------------------------------------------

class TestRepairFocused:
    def test_empty_input_returns_unchanged(self):
        result = repair_text("")
        assert result["original_text"] == ""
        assert result["repaired_text"] == ""
        assert result["changed"] is False
        assert result["issues_fixed"] == []
        assert result["suggestions"] == []

    def test_input_not_mutated(self):
        text = "مـحـمـد"
        snapshot = text[:]
        repair_text(text)
        assert text == snapshot

    def test_result_has_all_required_fields(self):
        result = repair_text("مرحبا")
        for field in _REQUIRED_RESULT_FIELDS:
            assert field in result, f"result missing field: {field!r}"

    def test_changed_false_when_no_repairs_needed(self):
        text = "العقد شريعة المتعاقدين."
        result = repair_text(text)
        assert result["changed"] is False
        assert result["repaired_text"] == text

    def test_tashkeel_preserved_by_default(self):
        text = "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ"
        result = repair_text(text)
        assert result["repaired_text"] == text
        assert result["changed"] is False

    def test_tatweel_removed_from_arabic_tokens(self):
        result = repair_text("مـحـمـد")
        assert result["repaired_text"] == "محمد"
        assert result["changed"] is True
        assert "AQ001_EXCESSIVE_TATWEEL" in result["issues_fixed"]

    def test_suggestions_is_list(self):
        for text in ["", "مرحبا", "مـحـمـد"]:
            result = repair_text(text)
            assert isinstance(result["suggestions"], list)

    def test_issues_fixed_is_list(self):
        result = repair_text("العقد شريعة المتعاقدين.")
        assert isinstance(result["issues_fixed"], list)
