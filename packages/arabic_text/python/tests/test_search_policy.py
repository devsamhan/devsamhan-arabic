"""AR-001 regression tests: strict/strict and loose/loose search policy.

These tests intentionally assert that strict-index/loose-query is a false
negative. They do not change library behavior.
"""

from devsamhan_arabic_text import (
    normalize_ta_marbouta,
    to_loose_search_key,
    to_search_key,
)

STORED = "فاطمة العلي"
QUERY_TA = "فاطمة"
QUERY_HA = "فاطمه"


def test_strict_strict_matches_same_spelling() -> None:
    assert to_search_key(QUERY_TA) in to_search_key(STORED)


def test_loose_loose_matches_both_spellings() -> None:
    loose_stored = to_loose_search_key(STORED)
    assert to_loose_search_key(QUERY_TA) in loose_stored
    assert to_loose_search_key(QUERY_HA) in loose_stored


def test_strict_loose_is_a_false_negative() -> None:
    strict_stored = to_search_key(STORED)
    assert to_loose_search_key(QUERY_TA) not in strict_stored
    assert to_loose_search_key(QUERY_HA) not in strict_stored


def test_loose_stored_key_derives_from_strict_key() -> None:
    assert normalize_ta_marbouta(to_search_key(STORED)) == to_loose_search_key(
        STORED
    )


def test_conservative_strict_key_preserves_ta_marbouta() -> None:
    assert to_search_key(STORED) == STORED
    assert to_search_key(QUERY_HA) == QUERY_HA
