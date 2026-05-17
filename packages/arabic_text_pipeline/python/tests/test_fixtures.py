"""
Fixture schema validation tests for arabic_text_pipeline.
Phase 1: verifies files exist and have correct structure.
No pipeline behavior is tested here.
"""

import json
import pathlib

FIXTURES_DIR = pathlib.Path(__file__).parent.parent.parent / "test_fixtures"

FIXTURE_FILES = [
    "quality.json",
    "repair.json",
    "chunking.json",
    "llm_prep.json",
]

REQUIRED_CASE_FIELDS = {"id", "name", "input", "expected"}


def load_fixture(filename: str) -> dict:
    path = FIXTURES_DIR / filename
    with path.open(encoding="utf-8") as f:
        return json.load(f)


class TestFixtureFilesExist:
    def test_spec_md_exists(self):
        assert (FIXTURES_DIR / "SPEC.md").exists(), "SPEC.md not found in test_fixtures/"

    def test_quality_json_exists(self):
        assert (FIXTURES_DIR / "quality.json").exists()

    def test_repair_json_exists(self):
        assert (FIXTURES_DIR / "repair.json").exists()

    def test_chunking_json_exists(self):
        assert (FIXTURES_DIR / "chunking.json").exists()

    def test_llm_prep_json_exists(self):
        assert (FIXTURES_DIR / "llm_prep.json").exists()


class TestFixtureStructure:
    def test_quality_has_cases(self):
        data = load_fixture("quality.json")
        assert "cases" in data
        assert len(data["cases"]) > 0

    def test_repair_has_cases(self):
        data = load_fixture("repair.json")
        assert "cases" in data
        assert len(data["cases"]) > 0

    def test_chunking_has_cases(self):
        data = load_fixture("chunking.json")
        assert "cases" in data
        assert len(data["cases"]) > 0

    def test_llm_prep_has_cases(self):
        data = load_fixture("llm_prep.json")
        assert "cases" in data
        assert len(data["cases"]) > 0

    def test_all_fixtures_have_fixture_version(self):
        for filename in FIXTURE_FILES:
            data = load_fixture(filename)
            assert "fixture_version" in data, f"{filename} missing fixture_version"


class TestCaseSchema:
    def _check_cases(self, filename: str):
        data = load_fixture(filename)
        for case in data["cases"]:
            missing = REQUIRED_CASE_FIELDS - set(case.keys())
            assert not missing, (
                f"{filename} case {case.get('id', '?')} missing fields: {missing}"
            )

    def test_quality_cases_have_required_fields(self):
        self._check_cases("quality.json")

    def test_repair_cases_have_required_fields(self):
        self._check_cases("repair.json")

    def test_chunking_cases_have_required_fields(self):
        self._check_cases("chunking.json")

    def test_llm_prep_cases_have_required_fields(self):
        self._check_cases("llm_prep.json")

    def _check_unique_ids(self, filename: str):
        data = load_fixture(filename)
        ids = [case["id"] for case in data["cases"]]
        assert len(ids) == len(set(ids)), f"{filename} has duplicate case IDs: {ids}"

    def test_quality_case_ids_are_unique(self):
        self._check_unique_ids("quality.json")

    def test_repair_case_ids_are_unique(self):
        self._check_unique_ids("repair.json")

    def test_chunking_case_ids_are_unique(self):
        self._check_unique_ids("chunking.json")

    def test_llm_prep_case_ids_are_unique(self):
        self._check_unique_ids("llm_prep.json")


class TestQualityFixtureContent:
    def test_quality_cases_have_arabic_ratio_or_issues(self):
        data = load_fixture("quality.json")
        for case in data["cases"]:
            exp = case["expected"]
            has_ratio = "arabic_ratio_min" in exp or "arabic_ratio_max" in exp
            has_quality = "quality" in exp
            assert has_ratio or has_quality, (
                f"quality case {case['id']} expected should have arabic_ratio or quality"
            )

    def test_quality_levels_are_valid(self):
        valid_levels = {"good", "warning", "poor"}
        data = load_fixture("quality.json")
        for case in data["cases"]:
            level = case["expected"].get("quality")
            if level is not None:
                assert level in valid_levels, (
                    f"quality case {case['id']} has invalid quality level: {level!r}"
                )


class TestRepairFixtureContent:
    def test_repair_cases_have_changed_field(self):
        data = load_fixture("repair.json")
        for case in data["cases"]:
            assert "changed" in case["expected"], (
                f"repair case {case['id']} missing 'changed' in expected"
            )

    def test_repair_changed_is_bool(self):
        data = load_fixture("repair.json")
        for case in data["cases"]:
            changed = case["expected"]["changed"]
            assert isinstance(changed, bool), (
                f"repair case {case['id']} 'changed' must be bool, got {type(changed)}"
            )


class TestChunkingFixtureContent:
    def test_chunking_cases_have_chunk_count(self):
        data = load_fixture("chunking.json")
        for case in data["cases"]:
            assert "chunk_count" in case["expected"], (
                f"chunking case {case['id']} missing 'chunk_count' in expected"
            )

    def test_chunking_chunk_types_are_valid(self):
        valid_types = {"book", "chapter", "section", "topic", "subtopic", "paragraph"}
        data = load_fixture("chunking.json")
        for case in data["cases"]:
            for chunk in case["expected"].get("chunks", []):
                ctype = chunk.get("type")
                if ctype is not None:
                    assert ctype in valid_types, (
                        f"chunking case {case['id']} chunk has invalid type: {ctype!r}"
                    )


class TestPackageImport:
    def test_spec_version_is_importable(self):
        from devsamhan_arabic_text_pipeline import SPEC_VERSION
        assert isinstance(SPEC_VERSION, str)
        assert SPEC_VERSION == "0.1.0"
