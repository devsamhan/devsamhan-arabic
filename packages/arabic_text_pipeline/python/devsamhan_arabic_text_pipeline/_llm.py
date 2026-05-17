"""
LLM preparation pipeline for Arabic text.
Orchestrates analyze_quality, repair_text, and chunk_semantic.
"""

from __future__ import annotations

import re

from devsamhan_arabic_text_pipeline._chunking import chunk_semantic
from devsamhan_arabic_text_pipeline._quality import _is_arabic, _is_tashkeel, analyze_quality
from devsamhan_arabic_text_pipeline._repair import repair_text

_PIPELINE_VERSION = "0.1.0"

# Alef variants normalized to plain alef for loose search keys.
_ALEF_TABLE = str.maketrans("أإآ", "ااا")  # أإآ → ا


def _strip_tashkeel(text: str) -> str:
    return "".join(ch for ch in text if not _is_tashkeel(ch))


def _make_loose_key(text: str) -> str:
    normed = _strip_tashkeel(text).translate(_ALEF_TABLE)
    normed = normed.replace("ة", "ه")  # ة → ه
    normed = normed.replace("ى", "ي")  # ى → ي
    return normed


def _collapse_blank_lines(text: str) -> str:
    return re.sub(r"\n{3,}", "\n\n", text)


def prepare_for_llm(
    text: str,
    *,
    include_search_key: bool = False,
    include_loose_search_key: bool = False,
    apply_repair: bool = True,
) -> dict:
    """
    Orchestrate quality analysis, optional repair, and chunking for LLM input.

    Does not mutate the input string.

    Args:
        text: Raw Arabic text.
        include_search_key: Produce a tashkeel-stripped search key.
        include_loose_search_key: Produce a loosely normalised search key (alef/ta-marbuta/alef-maqsura unified).
        apply_repair: Run repair_text() before cleaning. Default True.

    Returns a dict with keys:
        original_text, clean_text, quality_report, repair_report,
        chunks, search_key, loose_search_key, warnings, metadata.
    """
    # --- Step 1: repair ---
    if apply_repair:
        repair_report = repair_text(text)
        working = repair_report["repaired_text"]
    else:
        repair_report = None
        working = text

    # --- Step 2: LLM-specific normalisation (collapse multiple blank lines) ---
    clean_text = _collapse_blank_lines(working)

    # --- Step 3: quality on clean_text ---
    quality_report = analyze_quality(clean_text)
    issue_codes = {iss["code"] for iss in quality_report["issues"]}

    # --- Step 4: chunking ---
    chunks = chunk_semantic(clean_text)

    # --- Step 5: optional search keys ---
    search_key = _strip_tashkeel(clean_text) if include_search_key else None
    loose_search_key = _make_loose_key(clean_text) if include_loose_search_key else None

    # --- Step 6: warnings ---
    warnings: list[str] = []
    if not text.strip():
        warnings.append("empty_text")
    if quality_report["quality"] == "poor":
        warnings.append("poor_quality")
    if repair_report is not None and repair_report["suggestions"]:
        warnings.append("unsafe_repair_skipped")
    if "AQ002_TASHKEEL_DENSE" in issue_codes:
        warnings.append("tashkeel_preserved")

    # --- Step 7: metadata ---
    arabic_char_count = sum(1 for ch in clean_text if _is_arabic(ch))
    metadata = {
        "char_count": len(clean_text),
        "arabic_char_count": arabic_char_count,
        "arabic_ratio": quality_report["arabic_ratio"],
        "chunk_count": len(chunks),
        "quality": quality_report["quality"],
        "issue_count": len(quality_report["issues"]),
        "changed": clean_text != text,
        "pipeline_version": _PIPELINE_VERSION,
    }

    return {
        "original_text": text,
        "clean_text": clean_text,
        "quality_report": quality_report,
        "repair_report": repair_report,
        "chunks": chunks,
        "search_key": search_key,
        "loose_search_key": loose_search_key,
        "warnings": warnings,
        "metadata": metadata,
    }
