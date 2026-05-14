"""devsamhan-arabic-text — Arabic text normalization, devsamhan-arabic spec v1.0.0."""

from .normalize import (
    SPEC_VERSION,
    remove_tashkeel,
    remove_tatweel,
    normalize_alef,
    normalize_hamza,
    normalize_ya,
    normalize_ta_marbouta,
    normalize_presentation_forms,
    normalize_digits,
    is_arabic,
    arabic_ratio,
)
from .presets import (
    to_search_key,
    to_loose_search_key,
    to_display_key,
    to_slug,
    normalize_name,
    to_sort_key,
    sort_arabic,
    compare_arabic,
)

__all__ = [
    "SPEC_VERSION",
    "remove_tashkeel",
    "remove_tatweel",
    "normalize_alef",
    "normalize_hamza",
    "normalize_ya",
    "normalize_ta_marbouta",
    "normalize_presentation_forms",
    "normalize_digits",
    "is_arabic",
    "arabic_ratio",
    "to_search_key",
    "to_loose_search_key",
    "to_display_key",
    "to_slug",
    "normalize_name",
    "to_sort_key",
    "sort_arabic",
    "compare_arabic",
]
