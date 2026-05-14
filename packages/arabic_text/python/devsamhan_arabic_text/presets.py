"""Arabic text preset pipelines — devsamhan-arabic spec v1.0.0.

Processing order (mandatory per SPEC §Processing Order):
  1. normalize_presentation_forms
  2. remove_tatweel
  3. remove_tashkeel
  4. normalize_alef
  5. normalize_hamza
  6. normalize_ya  (ى + ی → ي)
  7. normalize_ta_marbouta  (explicit-only)
  8. normalize_digits       (explicit-only)
  9. trim + collapse whitespace
"""

import re
from .normalize import (
    normalize_presentation_forms,
    remove_tatweel,
    remove_tashkeel,
    normalize_alef,
    normalize_hamza,
    normalize_ya,
    normalize_ta_marbouta,
)

_WS_RE = re.compile(r"\s+")

_SLUG_ALLOWED_RE = re.compile("[^؀-ۿa-z0-9-]")


def _ws(s: str) -> str:
    return _WS_RE.sub(" ", s).strip()


def to_search_key(text: str) -> str:
    s = normalize_presentation_forms(text)  # 1
    s = remove_tatweel(s)                   # 2
    s = remove_tashkeel(s)                  # 3
    s = normalize_alef(s)                   # 4
    s = normalize_hamza(s)                  # 5
    s = normalize_ya(s)                     # 6
    return _ws(s)                           # 9


def to_loose_search_key(text: str) -> str:
    return normalize_ta_marbouta(to_search_key(text))


def to_display_key(text: str) -> str:
    s = normalize_presentation_forms(text)  # 1
    s = remove_tatweel(s)                   # 2
    return _ws(s)                           # 9


def to_slug(text: str) -> str:
    s = to_search_key(text)
    s = normalize_ta_marbouta(s)
    s = s.replace(" ", "-")
    s = s.lower()
    s = _SLUG_ALLOWED_RE.sub("", s)
    return s


def normalize_name(text: str) -> str:
    s = normalize_presentation_forms(text)  # 1
    s = remove_tatweel(s)                   # 2
    s = remove_tashkeel(s)                  # 3
    s = normalize_alef(s)                   # 4
    s = normalize_hamza(s)                  # 5
    s = s.replace("ی", "ي")                # Persian Ya only (U+06CC → U+064A)
    return _ws(s)                           # 9


def to_sort_key(text: str) -> str:
    return to_search_key(text)


def sort_arabic(items: list[str]) -> list[str]:
    return sorted(items, key=to_sort_key)


def compare_arabic(a: str, b: str) -> int:
    ka, kb = to_sort_key(a), to_sort_key(b)
    if ka < kb:
        return -1
    if ka > kb:
        return 1
    return 0
