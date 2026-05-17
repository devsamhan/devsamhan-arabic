"""
Deterministic semantic chunking for Arabic text.
"""

from __future__ import annotations

import re

_ARABIC_ORDINALS = (
    "أولاً", "ثانياً", "ثالثاً", "رابعاً", "خامساً",
    "سادساً", "سابعاً", "ثامناً", "تاسعاً", "عاشراً",
)

# Patterns are checked in priority order; first match wins.
_HEADING_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"^(الكتاب|كتاب)\b"), "book"),
    (re.compile(r"^(الباب|باب)\b"), "chapter"),
    (re.compile(r"^(الفصل|فصل)\b"), "section"),
    (re.compile(r"^(المبحث|مبحث)\b"), "topic"),
    (re.compile(r"^(المطلب|مطلب)\b"), "subtopic"),
    (
        re.compile(
            r"^(" + "|".join(re.escape(o) for o in _ARABIC_ORDINALS) + r")[\s:،]"
        ),
        "section",
    ),
]


def _detect_heading(line: str) -> tuple[str, str] | None:
    stripped = line.strip()
    if not stripped:
        return None
    for pattern, chunk_type in _HEADING_PATTERNS:
        if pattern.match(stripped):
            return (stripped, chunk_type)
    return None


def _find_heading_spans(text: str) -> list[tuple[int, str, str]]:
    """Return list of (start_pos, title, type) for each heading line found."""
    result = []
    pos = 0
    for line in text.split("\n"):
        heading = _detect_heading(line)
        if heading:
            result.append((pos, heading[0], heading[1]))
        pos += len(line) + 1
    return result


def _split_paragraphs(text: str) -> list[dict]:
    """Split text into paragraph chunks at double-newline boundaries."""
    chunks = []
    prev_end = 0

    for m in re.finditer(r"\n\n+", text):
        block = text[prev_end : m.start()]
        rstripped = block.rstrip()
        lstripped = rstripped.lstrip()
        if lstripped:
            leading = len(rstripped) - len(lstripped)
            start_index = prev_end + leading
            end_index = prev_end + len(rstripped)
            chunks.append({
                "title": None,
                "type": "paragraph",
                "text": lstripped,
                "start_index": start_index,
                "end_index": end_index,
            })
        prev_end = m.end()

    block = text[prev_end:]
    rstripped = block.rstrip()
    lstripped = rstripped.lstrip()
    if lstripped:
        leading = len(rstripped) - len(lstripped)
        start_index = prev_end + leading
        end_index = prev_end + len(rstripped)
        chunks.append({
            "title": None,
            "type": "paragraph",
            "text": lstripped,
            "start_index": start_index,
            "end_index": end_index,
        })

    return chunks


def chunk_semantic(text: str) -> list[dict]:
    """
    Split Arabic text into semantic chunks.

    Detects structural headings (باب، فصل، مبحث، مطلب، numbered ordinals) and
    creates one chunk per heading span. Falls back to double-newline paragraph
    splitting when no headings are found.

    Each chunk contains:
        title       – heading line text, or None for plain paragraphs
        type        – "book" | "chapter" | "section" | "topic" | "subtopic" | "paragraph"
        text        – substring of the original input (not mutated)
        start_index – inclusive start position in the original input
        end_index   – exclusive end position in the original input
    """
    if not text.strip():
        return []

    heading_spans = _find_heading_spans(text)

    if not heading_spans:
        return _split_paragraphs(text)

    chunks = []
    for i, (start, title, htype) in enumerate(heading_spans):
        end = heading_spans[i + 1][0] if i + 1 < len(heading_spans) else len(text)
        segment = text[start:end]
        rstripped = segment.rstrip()
        if not rstripped:
            continue
        actual_end = start + len(rstripped)
        chunks.append({
            "title": title,
            "type": htype,
            "text": rstripped,
            "start_index": start,
            "end_index": actual_end,
        })

    return chunks
