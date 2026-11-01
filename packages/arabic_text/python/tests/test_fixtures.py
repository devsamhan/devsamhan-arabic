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
    "robustness.json",
]


def _run_case(c: dict) -> object:
    op = c["operation"]
    inp = c["input"]
    opts = c.get("options", {})

    if op == "removeTashkeel":
        return api.remove_tashkeel(inp)
    elif op == "removeTatweel":
        return api.remove_tatweel(inp)
    elif op == "normalizeAlef":
        return api.normalize_alef(inp)
    elif op == "normalizeHamza":
        return api.normalize_hamza(inp)
    elif op == "normalizeYa":
        return api.normalize_ya(inp)
    elif op == "normalizeTaMarbouta":
        return api.normalize_ta_marbouta(inp)
    elif op == "normalizePresentationForms":
        return api.normalize_presentation_forms(inp)
    elif op == "normalizeDigits":
        return api.normalize_digits(inp, opts["to"])
    elif op == "toSearchKey":
        return api.to_search_key(inp)
    elif op == "toLooseSearchKey":
        return api.to_loose_search_key(inp)
    elif op == "toDisplayKey":
        return api.to_display_key(inp)
    elif op == "toSlug":
        return api.to_slug(inp)
    elif op == "normalizeName":
        return api.normalize_name(inp)
    elif op == "toSortKey":
        if isinstance(inp, list):
            return [api.to_sort_key(s) for s in inp]
        return api.to_sort_key(inp)
    elif op == "sort":
        return api.sort_arabic(inp)
    elif op == "compare":
        return api.compare_arabic(inp[0], inp[1])
    elif op == "isArabic":
        return api.is_arabic(inp)
    elif op == "arabicRatio":
        return api.arabic_ratio(inp)
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
