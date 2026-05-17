"""
Quality analysis for Arabic text.
"""

from __future__ import annotations

TATWEEL = "ـ"       # ـ  (kashida)
TA_MARBUTA = "ة"    # ة  — always word-final in standard Arabic
ALEF_MAQSURA = "ى"  # ى  — always word-final in standard Arabic
_LAM_ALEF = "لا"  # لا — reversed definite article ال

_ARABIC_RANGES = (
    (0x0600, 0x06FF),   # Arabic
    (0x0750, 0x077F),   # Arabic Supplement
    (0xFB50, 0xFDFF),   # Arabic Presentation Forms-A
    (0xFE70, 0xFEFF),   # Arabic Presentation Forms-B
)

# AQ007 threshold: flag when arabic_ratio < this value.
# 0.65 rather than the SPEC default of 0.5 — see fixture quality-004 notes.
_AQ007_THRESHOLD = 0.65

# Characters that are acceptable (not noise) in Arabic or mixed Arabic/Latin prose.
_OK_NON_ARABIC: frozenset[str] = frozenset(
    "abcdefghijklmnopqrstuvwxyz"
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    "0123456789"
    " \t\n\r"
    r""".,;:!?"'()[]{}/-\_"""
    "«»،؛؟"
)


def _is_arabic(ch: str) -> bool:
    cp = ord(ch)
    return any(lo <= cp <= hi for lo, hi in _ARABIC_RANGES)


def _is_tashkeel(ch: str) -> bool:
    cp = ord(ch)
    return (0x064B <= cp <= 0x065F) or cp == 0x0670  # harakat + superscript alef


def _is_noise(ch: str) -> bool:
    return not _is_arabic(ch) and ch not in _OK_NON_ARABIC


def _base_letters(core: str) -> str:
    return "".join(
        ch for ch in core
        if _is_arabic(ch) and not _is_tashkeel(ch) and ch != TATWEEL
    )


def _issue(code: str, severity: str, message: str, evidence: str | None = None) -> dict:
    return {"code": code, "severity": severity, "message": message, "evidence": evidence}


def analyze_quality(text: str) -> dict:
    """
    Analyze the quality of Arabic text.

    Returns original_text, arabic_ratio, quality level, and a list of issues.
    Does not mutate the input.
    """
    issues: list[dict] = []

    non_ws = [ch for ch in text if not ch.isspace()]

    # Empty / whitespace-only: early return, skip all other checks.
    if not non_ws:
        issues.append(_issue(
            "AQ007_LOW_ARABIC_RATIO", "high",
            "Text is empty or contains only whitespace.",
        ))
        return {
            "original_text": text,
            "arabic_ratio": 0.0,
            "quality": "poor",
            "issues": issues,
        }

    arabic_count = sum(1 for ch in non_ws if _is_arabic(ch))
    arabic_ratio = arabic_count / len(non_ws)

    # AQ006: OCR noise characters
    noise_chars = [ch for ch in non_ws if _is_noise(ch)]
    noise_ratio = len(noise_chars) / len(non_ws)
    if noise_ratio >= 0.10:
        issues.append(_issue(
            "AQ006_OCR_NOISE", "high",
            f"High OCR noise ratio: {noise_ratio:.1%} of characters are noise symbols.",
            evidence="".join(noise_chars[:20]) or None,
        ))
    elif noise_ratio >= 0.02:
        issues.append(_issue(
            "AQ006_OCR_NOISE", "medium",
            f"Moderate OCR noise: {noise_ratio:.1%} of characters are noise symbols.",
            evidence="".join(noise_chars[:20]) or None,
        ))

    # AQ007: Low Arabic ratio (content exists but ratio below threshold)
    if arabic_ratio < _AQ007_THRESHOLD:
        issues.append(_issue(
            "AQ007_LOW_ARABIC_RATIO", "medium",
            f"Low Arabic ratio: {arabic_ratio:.1%} of non-whitespace characters are Arabic "
            f"(threshold: {_AQ007_THRESHOLD:.0%}).",
        ))

    # AQ001: Tatweel inside Arabic words.
    # Flag any tatweel (U+0640) that is immediately adjacent to an Arabic base letter.
    # Severity: medium when there are consecutive runs (max_run >= 2); low for isolated usage.
    # Standalone tatweel surrounded by spaces (em-dash style) is NOT flagged.
    tatweel_in_words = 0
    max_run = current_run = 0
    for i, ch in enumerate(text):
        if ch == TATWEEL:
            current_run += 1
            if current_run > max_run:
                max_run = current_run
            prev_arabic_base = (
                i > 0
                and _is_arabic(text[i - 1])
                and text[i - 1] != TATWEEL
            )
            next_arabic_base = (
                i < len(text) - 1
                and _is_arabic(text[i + 1])
                and text[i + 1] != TATWEEL
            )
            if prev_arabic_base or next_arabic_base:
                tatweel_in_words += 1
        else:
            current_run = 0

    if tatweel_in_words:
        if max_run >= 2:
            severity = "medium"
            message = f"Consecutive tatweel (kashida) decoration detected (max run: {max_run})."
        else:
            severity = "low"
            message = (
                f"Tatweel (kashida) found inside {tatweel_in_words} "
                "Arabic word position(s); repair will remove it."
            )
        issues.append(_issue("AQ001_EXCESSIVE_TATWEEL", severity, message))

    # AQ002: Dense tashkeel
    arabic_base = sum(
        1 for ch in text
        if _is_arabic(ch) and not _is_tashkeel(ch) and ch != TATWEEL
    )
    tashkeel_count = sum(1 for ch in text if _is_tashkeel(ch))
    if arabic_base > 0 and tashkeel_count / arabic_base > 0.30:
        issues.append(_issue(
            "AQ002_TASHKEEL_DENSE", "low",
            f"Dense tashkeel: diacritics on {tashkeel_count / arabic_base:.0%} of base Arabic characters.",
        ))

    # Build Arabic word cores (Arabic chars extracted from each whitespace-delimited token)
    arabic_cores = []
    for token in text.split():
        core = "".join(ch for ch in token if _is_arabic(ch))
        if core:
            arabic_cores.append(core)

    # AQ003: Possibly reversed — word core starts with ة/ى, or base core (len≥5) ends with لا
    if arabic_cores:
        reversed_starts = [
            w for w in arabic_cores
            if len(w) >= 2 and w[0] in (TA_MARBUTA, ALEF_MAQSURA)
        ]
        reversed_by_article = [
            w for w in arabic_cores
            if len(_base_letters(w)) >= 5 and _base_letters(w).endswith(_LAM_ALEF)
        ]
        if reversed_starts or reversed_by_article:
            evidence = (reversed_starts or reversed_by_article)[0]
            issues.append(_issue(
                "AQ003_POSSIBLY_REVERSED", "medium",
                "Arabic words begin with characters (ة/ى) that are always word-final, "
                "or end with a reversed definite article (لا), suggesting visually reversed text.",
                evidence=evidence,
            ))

    # AQ004: Separated letters — high ratio of single-char Arabic word cores
    if arabic_cores:
        single_char_count = sum(1 for w in arabic_cores if len(w) == 1)
        sep_ratio = single_char_count / len(arabic_cores)
        if sep_ratio > 0.50:
            issues.append(_issue(
                "AQ004_SEPARATED_LETTERS", "medium",
                f"{sep_ratio:.0%} of Arabic words are single characters, "
                "suggesting separated or broken text.",
            ))

    # AQ005: Mixed digit forms (Western + Arabic-Indic/Persian)
    has_western = any("0" <= ch <= "9" for ch in text)
    has_eastern = any(
        ("٠" <= ch <= "٩") or ("۰" <= ch <= "۹")
        for ch in text
    )
    if has_western and has_eastern:
        issues.append(_issue(
            "AQ005_MIXED_DIGITS", "low",
            "Text contains both Western (0–9) and Arabic-Indic/Persian digit forms.",
        ))

    # Roll-up: highest severity determines quality level
    severities = {iss["severity"] for iss in issues}
    if "high" in severities:
        quality = "poor"
    elif "medium" in severities:
        quality = "warning"
    else:
        quality = "good"

    return {
        "original_text": text,
        "arabic_ratio": round(arabic_ratio, 4),
        "quality": quality,
        "issues": issues,
    }
