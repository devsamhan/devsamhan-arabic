"""
Fixture-driven behavioral tests for analyze_quality().
Phase 2A — covers quality.json cases only.
"""

import json
import pathlib

import pytest

from devsamhan_arabic_text_pipeline import analyze_quality

FIXTURES_DIR = pathlib.Path(__file__).parent.parent.parent / "test_fixtures"

_REQUIRED_ISSUE_FIELDS = {"code", "severity", "message", "evidence"}
_VALID_SEVERITIES = {"low", "medium", "high"}
_VALID_QUALITIES = {"good", "warning", "poor"}


def _load_cases(filename: str) -> list[dict]:
    with (FIXTURES_DIR / filename).open(encoding="utf-8") as f:
        return json.load(f)["cases"]


_QUALITY_CASES = _load_cases("quality.json")


# ---------------------------------------------------------------------------
# Fixture-driven parametrised tests — one test per case in quality.json
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("case", _QUALITY_CASES, ids=[c["id"] for c in _QUALITY_CASES])
def test_quality_fixture(case):
    result = analyze_quality(case["input"])
    exp = case["expected"]

    # original_text must be returned unchanged
    assert result["original_text"] == case["input"], (
        f"[{case['id']}] original_text was modified"
    )

    # arabic_ratio must be a float
    assert isinstance(result["arabic_ratio"], float), (
        f"[{case['id']}] arabic_ratio is not float: {type(result['arabic_ratio'])}"
    )

    # arabic_ratio bounds
    if "arabic_ratio_min" in exp:
        assert result["arabic_ratio"] >= exp["arabic_ratio_min"], (
            f"[{case['id']}] arabic_ratio={result['arabic_ratio']:.4f} "
            f"< expected min={exp['arabic_ratio_min']}"
        )
    if "arabic_ratio_max" in exp:
        assert result["arabic_ratio"] <= exp["arabic_ratio_max"], (
            f"[{case['id']}] arabic_ratio={result['arabic_ratio']:.4f} "
            f"> expected max={exp['arabic_ratio_max']}"
        )

    # quality level must match exactly
    assert result["quality"] == exp["quality"], (
        f"[{case['id']}] quality={result['quality']!r}, "
        f"expected={exp['quality']!r}; "
        f"actual issues={[i['code'] for i in result['issues']]}"
    )

    # issue code set must match exactly
    if "issues" in exp:
        result_codes = {iss["code"] for iss in result["issues"]}
        expected_codes = set(exp["issues"])
        assert result_codes == expected_codes, (
            f"[{case['id']}] "
            f"got={sorted(result_codes)}, "
            f"expected={sorted(expected_codes)}"
        )

    # every returned issue must have the required shape
    for iss in result["issues"]:
        missing = _REQUIRED_ISSUE_FIELDS - set(iss.keys())
        assert not missing, (
            f"[{case['id']}] issue {iss.get('code', '?')} missing fields: {missing}"
        )
        assert iss["severity"] in _VALID_SEVERITIES, (
            f"[{case['id']}] invalid severity: {iss['severity']!r}"
        )
        assert isinstance(iss["message"], str) and iss["message"], (
            f"[{case['id']}] message must be a non-empty string"
        )
        assert iss["evidence"] is None or isinstance(iss["evidence"], str), (
            f"[{case['id']}] evidence must be str or None"
        )


# ---------------------------------------------------------------------------
# Focused unit tests
# ---------------------------------------------------------------------------

class TestQualityFocused:
    def test_empty_input_returns_poor_with_aq007(self):
        result = analyze_quality("")
        assert result["quality"] == "poor"
        assert result["arabic_ratio"] == 0.0
        codes = {iss["code"] for iss in result["issues"]}
        assert "AQ007_LOW_ARABIC_RATIO" in codes

    def test_whitespace_only_returns_poor_with_aq007(self):
        result = analyze_quality("   \n\t  \n  ")
        assert result["quality"] == "poor"
        assert result["arabic_ratio"] == 0.0
        codes = {iss["code"] for iss in result["issues"]}
        assert "AQ007_LOW_ARABIC_RATIO" in codes

    def test_clean_arabic_paragraph_returns_good_no_issues(self):
        text = "العقد شريعة المتعاقدين، ولا يجوز نقضه إلا باتفاق الطرفين أو بحكم القانون."
        result = analyze_quality(text)
        assert result["quality"] == "good"
        assert result["issues"] == []

    def test_original_text_preserved_exactly(self):
        text = "مـحـمـد   بـن   عـبـد   الله\n\n"
        result = analyze_quality(text)
        assert result["original_text"] == text

    def test_input_not_mutated(self):
        text = "العقد شريعة المتعاقدين"
        snapshot = text[:]
        analyze_quality(text)
        assert text == snapshot

    def test_result_quality_is_one_of_three_levels(self):
        for text in ["", "hello", "مرحبا"]:
            result = analyze_quality(text)
            assert result["quality"] in _VALID_QUALITIES

    def test_single_tatweel_in_word_triggers_aq001_low(self):
        # "مـحـمـد" has isolated tatweels between Arabic letters — adjacent, not consecutive.
        result = analyze_quality("مـحـمـد")
        codes = {iss["code"] for iss in result["issues"]}
        assert "AQ001_EXCESSIVE_TATWEEL" in codes
        aq001 = next(i for i in result["issues"] if i["code"] == "AQ001_EXCESSIVE_TATWEEL")
        assert aq001["severity"] == "low"
        assert result["quality"] == "good"   # low-only → quality stays good

    def test_consecutive_tatweel_run_triggers_aq001_medium(self):
        # "مـــحمد" has a run of 3 consecutive tatweels — should be medium severity.
        result = analyze_quality("مـــحمد")
        codes = {iss["code"] for iss in result["issues"]}
        assert "AQ001_EXCESSIVE_TATWEEL" in codes
        aq001 = next(i for i in result["issues"] if i["code"] == "AQ001_EXCESSIVE_TATWEEL")
        assert aq001["severity"] == "medium"
        assert result["quality"] == "warning"

    def test_standalone_tatweel_em_dash_style_not_flagged(self):
        # "مالك ـ رحمه" — tatweel surrounded by spaces, used as punctuation separator.
        # quality-012 fixture also verifies this; this focused test makes the intent explicit.
        text = "قال الإمام مالك ـ رحمه الله ـ في المدوّنة: لا بأس بذلك."
        result = analyze_quality(text)
        codes = {iss["code"] for iss in result["issues"]}
        assert "AQ001_EXCESSIVE_TATWEEL" not in codes
        assert result["quality"] == "good"
