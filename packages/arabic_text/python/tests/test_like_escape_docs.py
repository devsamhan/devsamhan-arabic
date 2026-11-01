"""AR-010 documentation helper tests (test-only, not a runtime API)."""

from typing import Optional


def escape_like(value: str) -> str:
    return value.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


def contains_pattern(value: str) -> Optional[str]:
    return None if value == "" else f"%{escape_like(value)}%"


def test_empty_query_is_not_sent_as_double_percent() -> None:
    assert escape_like("") == ""
    assert contains_pattern("") is None


def test_ordinary_arabic_is_unchanged() -> None:
    assert escape_like("فاطمة") == "فاطمة"
    assert contains_pattern("فاطمة") == "%فاطمة%"


def test_percent_is_literal() -> None:
    assert escape_like("100%") == r"100\%"
    assert contains_pattern("100%") == r"%100\%%"


def test_underscore_is_literal() -> None:
    assert escape_like("a_b") == r"a\_b"
    assert contains_pattern("a_b") == r"%a\_b%"


def test_backslash_is_escaped_first() -> None:
    assert escape_like("a\\b") == "a\\\\b"


def test_all_special_characters_together() -> None:
    assert escape_like("%_\\") == "\\%\\_\\\\"
