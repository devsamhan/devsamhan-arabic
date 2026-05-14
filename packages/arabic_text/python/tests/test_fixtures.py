"""Fixture-driven tests — loads all cases from test_fixtures/ at monorepo root."""

import json
import pytest
from pathlib import Path
import devsamhan_arabic_text as api

# packages/arabic_text/python/tests/ → 5 parents → monorepo root
_FIXTURES_DIR = Path(__file__).resolve().parent.parent.parent.parent.parent / "test_fixtures"

_FIXTURE_FILES = [
    "normalize.json",
    "search_key.json",
    "numbers.json",
    "mixed_text.json",
    "sorting.json",
]


def _run_case(c: dict) -> object:
    op = c["operation"]
    inp = c["input"]
    opts = c.get("options", {})

    match op:
        case "removeTashkeel":
            return api.remove_tashkeel(inp)
        case "removeTatweel":
            return api.remove_tatweel(inp)
        case "normalizeAlef":
            return api.normalize_alef(inp)
        case "normalizeHamza":
            return api.normalize_hamza(inp)
        case "normalizeYa":
            return api.normalize_ya(inp)
        case "normalizeTaMarbouta":
            return api.normalize_ta_marbouta(inp)
        case "normalizePresentationForms":
            return api.normalize_presentation_forms(inp)
        case "normalizeDigits":
            return api.normalize_digits(inp, opts["to"])
        case "toSearchKey":
            return api.to_search_key(inp)
        case "toLooseSearchKey":
            return api.to_loose_search_key(inp)
        case "toDisplayKey":
            return api.to_display_key(inp)
        case "toSlug":
            return api.to_slug(inp)
        case "normalizeName":
            return api.normalize_name(inp)
        case "toSortKey":
            if isinstance(inp, list):
                return [api.to_sort_key(s) for s in inp]
            return api.to_sort_key(inp)
        case "sort":
            return api.sort_arabic(inp)
        case "compare":
            return api.compare_arabic(inp[0], inp[1])
        case "isArabic":
            return api.is_arabic(inp)
        case "arabicRatio":
            return api.arabic_ratio(inp)
        case _:
            raise ValueError(f"Unknown operation: {op}")


def _load_cases() -> list[tuple[str, dict]]:
    cases = []
    for filename in _FIXTURE_FILES:
        data = json.loads((_FIXTURES_DIR / filename).read_text(encoding="utf-8"))
        for c in data["cases"]:
            cases.append((f"[{c['id']}] {c.get('name', c['operation'])}", c))
    return cases


_ALL_CASES = _load_cases()


@pytest.mark.parametrize("label,case", _ALL_CASES, ids=[label for label, _ in _ALL_CASES])
def test_fixture(label: str, case: dict) -> None:
    actual = _run_case(case)
    assert actual == case["expected"]
