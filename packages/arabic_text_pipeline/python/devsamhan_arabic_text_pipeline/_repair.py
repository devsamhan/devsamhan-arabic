"""
Conservative Arabic text repair.
"""

from __future__ import annotations

import re

from devsamhan_arabic_text_pipeline._quality import TATWEEL, _is_arabic, analyze_quality

# Zero-width chars and bidi marks that appear as invisible noise in PDF-extracted text.
_FORMAT_CHARS: frozenset[str] = frozenset([
    "​",  # ZWSP
    "‌",  # ZWNJ
    "‍",  # ZWJ
    "﻿",  # BOM / ZWNBSP
    "‪",  # LTR embedding
    "‫",  # RTL embedding
    "‬",  # PDF
    "‭",  # LTR override
    "‮",  # RTL override
    "⁦",  # LTR isolate
    "⁧",  # RTL isolate
    "⁨",  # first-strong isolate
    "⁩",  # pop directional isolate
])


def _remove_format_chars(text: str) -> str:
    return "".join(ch for ch in text if ch not in _FORMAT_CHARS)


def _remove_inline_tatweel(text: str) -> tuple[str, bool]:
    parts = re.split(r"(\s+)", text)
    changed = False
    result = []
    for part in parts:
        if part and not part.isspace():
            has_base = any(_is_arabic(ch) and ch != TATWEEL for ch in part)
            if has_base and TATWEEL in part:
                part = part.replace(TATWEEL, "")
                changed = True
        result.append(part)
    return "".join(result), changed


def _normalize_whitespace(text: str) -> str:
    text = text.replace("\r\n", "\n")
    lines = [line.rstrip(" \t") for line in text.split("\n")]
    text = "\n".join(lines)
    text = re.sub(r"[ \t]{2,}", " ", text)
    return text


def _build_suggestions(original: str) -> list[dict]:
    suggestions = []
    report = analyze_quality(original)
    codes = {iss["code"] for iss in report["issues"]}
    if "AQ003_POSSIBLY_REVERSED" in codes:
        suggestions.append({
            "type": "reverse_text",
            "reason": "AQ003_POSSIBLY_REVERSED",
            "safe": False,
        })
    if "AQ004_SEPARATED_LETTERS" in codes:
        suggestions.append({
            "type": "merge_separated_letters",
            "reason": "AQ004_SEPARATED_LETTERS",
            "safe": False,
        })
    return suggestions


def repair_text(text: str) -> dict:
    """
    Apply conservative repairs to Arabic text.

    Safe repairs applied automatically: tatweel removal, whitespace normalization,
    zero-width and bidi format character removal.
    Unsafe repairs (reversing, merging) are returned as suggestions only.
    Does not mutate the input.
    """
    working = text
    issues_fixed: list[str] = []

    working = _remove_format_chars(working)
    working, tatweel_changed = _remove_inline_tatweel(working)
    if tatweel_changed:
        issues_fixed.append("AQ001_EXCESSIVE_TATWEEL")
    working = _normalize_whitespace(working)

    changed = working != text
    suggestions = _build_suggestions(text)

    return {
        "original_text": text,
        "repaired_text": working,
        "changed": changed,
        "issues_fixed": issues_fixed,
        "suggestions": suggestions,
    }
