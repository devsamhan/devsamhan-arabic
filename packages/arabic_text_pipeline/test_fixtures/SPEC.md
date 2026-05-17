# arabic_text_pipeline — Behavioral Specification

**SPEC_VERSION:** 0.1.0  
**Status:** Draft  
**Last updated:** 2026-05-17

---

## Table of Contents

1. [Purpose](#1-purpose)
2. [Non-goals](#2-non-goals)
3. [Pipeline philosophy](#3-pipeline-philosophy)
4. [Definitions](#4-definitions)
5. [Quality scoring](#5-quality-scoring)
6. [Repair policy](#6-repair-policy)
7. [Safe vs unsafe repair](#7-safe-vs-unsafe-repair)
8. [Broken Arabic detection](#8-broken-arabic-detection)
9. [OCR noise detection](#9-ocr-noise-detection)
10. [PDF extraction damage detection](#10-pdf-extraction-damage-detection)
11. [Semantic chunking](#11-semantic-chunking)
12. [LLM preparation](#12-llm-preparation)
13. [Output object shapes](#13-output-object-shapes)
14. [Fixture format](#14-fixture-format)
15. [Contribution rules](#15-contribution-rules)
16. [Open questions](#16-open-questions)

---

## 1. Purpose

`arabic_text_pipeline` is a Python library for analyzing, cleaning, repairing, and structuring Arabic text **after** it has been extracted from a source document.

It operates on plain text strings. It does not interact with files, images, PDFs, or any document format. The caller is responsible for obtaining the raw text; this library is responsible for making that text usable.

Typical callers:
- A post-OCR cleanup step
- A post-PDF-extraction normalization pass
- A preprocessing stage before LLM ingestion
- A quality gate that rejects or flags low-quality extractions

---

## 2. Non-goals

The following are explicitly outside the scope of this package:

| Non-goal | Why excluded |
|---|---|
| PDF parsing | Use PyMuPDF, pdfplumber, or similar |
| OCR execution | Use PaddleOCR, Tesseract, or similar |
| Image processing | Out of scope entirely |
| Arabic NLP (NER, POS tagging) | Future package; not here |
| Arabic stemming or morphological analysis | Future package; not here |
| Translation | Out of scope |
| Sentiment analysis | Out of scope |
| Training data generation | Out of scope |

---

## 3. Pipeline philosophy

### 3.1 Never silently destroy the original

Every pipeline output preserves `original_text` as an unmodified copy of the input. Nothing in this library overwrites the caller's input string. This is a hard invariant.

### 3.2 Repair output is always separate

Repaired text is placed in `repaired_text`. The original lives in `original_text`. If no repair was performed, `repaired_text` equals `original_text` and `changed` is `false`.

### 3.3 Unsafe repairs are suggestions only

If the pipeline determines that a repair is ambiguous, irreversible, or could destroy meaning, it MUST NOT apply that repair automatically. Instead, it records the issue in `suggestions[]` and leaves the text unchanged.

### 3.4 Quality reports are explainable

Every detected issue in a quality report MUST have:
- A named issue code (e.g. `AQ001_EXCESSIVE_TATWEEL`)
- A human-readable `description` string
- A `severity` level: `info`, `warning`, or `error`
- An optional `span` indicating where in the text the issue was found

Callers must be able to understand why a quality score was assigned without reading source code.

### 3.5 Arabic repair is conservative by default

The pipeline assumes text is from a known-good source unless it has strong evidence otherwise. It does not aggressively normalize or "fix" text that might simply be styled differently. When in doubt, preserve.

### 3.6 Separation of concerns

The pipeline has four distinct stages, each independently callable:
1. **Quality analysis** — assess the input, produce a quality report
2. **Repair** — apply safe repairs, record unsafe ones as suggestions
3. **Chunking** — split into semantic units
4. **LLM preparation** — finalize for downstream consumption

Each stage can be run in isolation. The full pipeline runs all four in sequence.

---

## 4. Definitions

| Term | Definition |
|---|---|
| **Arabic ratio** | The fraction of non-whitespace characters that are Arabic Unicode characters (U+0600–U+06FF, U+0750–U+077F, U+FB50–U+FDFF, U+FE70–U+FEFF) |
| **Tatweel** | The Arabic kashida character U+0640 (ـ), used for visual stretching. Excessive tatweel is decoration, not meaning. |
| **Tashkeel** | Diacritical marks on Arabic letters (harakat): fatha, kasra, damma, sukun, shadda, etc. (U+064B–U+065F) |
| **Isolated letters** | Arabic characters that appear separated by spaces when they should form connected words — a common OCR failure mode |
| **Reversed text** | Text that appears to have been stored or copied in wrong visual order, causing Arabic to render left-to-right instead of right-to-left |
| **OCR noise** | Spurious characters inserted by an OCR engine: random punctuation, digit substitutions, Latin characters in place of Arabic |
| **Broken Arabic** | Arabic text where the character sequence is corrupted — letters are out of order, isolated, or substituted |
| **Structural heading** | An Arabic heading that indicates a document section: باب (chapter), فصل (section), مبحث (topic), مطلب (subtopic) |
| **Semantic chunk** | A contiguous span of text with a single semantic role: a heading plus its body, a standalone paragraph |
| **Quality level** | A three-way rating: `good`, `warning`, `poor` |
| **Safe repair** | A repair that is deterministic, reversible in context, and cannot destroy meaning (e.g. removing kashida between letters) |
| **Unsafe repair** | A repair that is ambiguous, potentially lossy, or requires human judgment (e.g. reversing a string suspected of being backwards) |

---

## 5. Quality scoring

### 5.1 Scoring algorithm

Quality scoring is deterministic. Given the same input, the pipeline always returns the same quality level and the same set of issues.

The algorithm:
1. Compute `arabic_ratio` — the fraction of non-whitespace characters that are Arabic
2. Check for each named issue (see §5.2)
3. Assign a severity to each found issue
4. Determine overall quality level from the highest severity:
   - Any `error` severity issue → `poor`
   - Any `warning` severity issue and no `error` → `warning`
   - No issues, or only `info` issues → `good`

### 5.2 Issue codes

| Code | Name | Severity | Detection method |
|---|---|---|---|
| `AQ001_EXCESSIVE_TATWEEL` | Excessive Tatweel | `warning` | More than N tatweel characters per 100 Arabic chars (default N=5) |
| `AQ002_TASHKEEL_DENSE` | Dense Tashkeel | `info` | Tashkeel density exceeds threshold (default >30% of Arabic chars) |
| `AQ003_POSSIBLY_REVERSED` | Possibly Reversed | `warning` | Heuristic: common Arabic word fragments appear as reversed substrings |
| `AQ004_SEPARATED_LETTERS` | Separated Letters | `warning` | Unusually high ratio of single Arabic characters surrounded by spaces |
| `AQ005_MIXED_DIGITS` | Mixed Digits | `info` | Both Arabic-Indic (٠١٢...) and Western (012...) digits present |
| `AQ006_OCR_NOISE` | OCR Noise | `error` | High ratio of non-Arabic, non-Latin, non-digit, non-punctuation characters |
| `AQ007_LOW_ARABIC_RATIO` | Low Arabic Ratio | `warning` | `arabic_ratio` below 0.5 for text claimed to be Arabic |

### 5.3 Empty text

An empty string or whitespace-only string is a special case:
- `arabic_ratio` = 0.0
- `quality` = `poor`
- Issues: `[AQ007_LOW_ARABIC_RATIO]`
- No other checks are run

### 5.4 Thresholds

All thresholds MUST be configurable at call time. The defaults documented in §5.2 are used when the caller does not specify overrides.

---

## 6. Repair policy

### 6.1 What repair does

The repair stage takes a quality report and attempts to fix issues that are safe to fix automatically (see §7). It returns:
- `repaired_text` — the text after safe repairs
- `original_text` — unchanged copy of the input
- `changed` — boolean, true if any repair was applied
- `issues_fixed` — list of issue codes that were resolved
- `suggestions` — list of suggested repairs for unsafe issues

### 6.2 Repair order

When multiple repairs apply, they are applied in this order:
1. Tatweel removal
2. Whitespace normalization
3. OCR noise removal (conservative)

Order matters because later repairs run on the output of earlier ones.

### 6.3 Non-modifiable content

The following MUST never be modified by repair, regardless of how they score:
- Quranic text (detected by presence of Quran-specific Unicode marks)
- Text inside quotation marks (`"..."`, `«...»`, `"..."`)
- Latin-script identifiers: file names, invoice numbers, URLs, email addresses, version strings
- Numeric codes (phone numbers, IDs, reference numbers)

---

## 7. Safe vs unsafe repair

### 7.1 Safe repairs (applied automatically)

| Repair | Condition | Notes |
|---|---|---|
| Remove tatweel | Kashida U+0640 appears between Arabic letters | Never remove tatweel that is the only character in a word |
| Normalize Unicode whitespace | Multiple consecutive spaces, tabs, or mixed whitespace | Collapse to single space |
| Remove trailing whitespace | End-of-line whitespace | Standard normalization |
| Normalize line endings | Mixed `\r\n` / `\n` | Normalize to `\n` |
| Remove zero-width characters | U+200B, U+200C, U+200D, U+FEFF (except BOM at position 0) | Common OCR artifacts |

### 7.2 Unsafe repairs (suggestions only)

| Repair | Why unsafe |
|---|---|
| Reversing text | May destroy intentionally reversed text, RTL markers, or bidirectional content |
| Merging separated letters | Ambiguous: isolated letters may be abbreviations, list markers, or intentional |
| Removing tashkeel | Destroys Quranic text and classical Arabic; callers opt in explicitly |
| Substituting OCR-confused characters | Requires context; wrong substitution destroys meaning |
| Reordering words | Requires morphological understanding |

### 7.3 Opt-in unsafe repairs

A caller may explicitly enable unsafe repairs by passing flags. When an unsafe repair is enabled:
- It is applied
- It is recorded in `issues_fixed`
- A `warning` is added to the output noting that an unsafe repair was applied
- `original_text` STILL preserves the unmodified input

---

## 8. Broken Arabic detection

### 8.1 What "broken Arabic" means

Broken Arabic is Arabic text where the character sequence does not form valid Arabic word shapes. This can happen because:
- OCR read characters in the wrong order
- Copy-paste from a right-to-left rendering context produced reversed bytes
- Character substitution introduced non-Arabic characters into Arabic words
- Word boundaries were destroyed (letters merged across word boundaries or split within words)

### 8.2 Detection heuristics

The pipeline uses conservative heuristics:

**Separated letters:** Count Arabic single-character "words" (Arabic character surrounded by spaces or at text boundary). If this ratio exceeds 30% of total Arabic words, flag `AQ004_SEPARATED_LETTERS`.

**Reversed text:** Check whether reversing the entire string (or portions of it) produces a higher frequency of known Arabic word patterns. Flag `AQ003_POSSIBLY_REVERSED` if reversal score is significantly higher. Never auto-repair.

**Word shape entropy:** Compute average Arabic word length. Unusually short average word length (< 2 characters/word) combined with high separated-letter count indicates broken text.

### 8.3 What broken Arabic detection does NOT do

- Does not attempt to reconstruct the original text
- Does not use a dictionary or language model
- Does not produce a "corrected" sequence
- Does not report confidence levels (binary detect/not-detect)

---

## 9. OCR noise detection

### 9.1 OCR noise patterns

The following patterns indicate OCR noise:

| Pattern | Example | Issue |
|---|---|---|
| Latin chars embedded in Arabic words | `محم8د` | Digit/letter substitution |
| Isolated punctuation clusters | `.. , .` | Artifact characters |
| High ratio of uncommon Unicode | Many U+25xx box-drawing characters | Scanner artifact |
| Repeated identical short sequences | `لل لل لل` | OCR repetition error |
| Characters from unrelated scripts | Cyrillic, Greek mixed in | OCR script confusion |

### 9.2 Noise ratio

Noise ratio = (number of noise characters) / (total non-whitespace characters)

- Noise ratio < 0.02 → no issue flagged
- 0.02 ≤ noise ratio < 0.10 → `AQ006_OCR_NOISE` at `warning`
- Noise ratio ≥ 0.10 → `AQ006_OCR_NOISE` at `error`

### 9.3 Conservative noise removal

When noise removal is applied (safe only):
- Only remove characters that are unambiguously non-Arabic, non-Latin, non-digit noise
- Zero-width joiners, non-joiners, and directional marks are removed as they are common OCR insertion artifacts
- Do not remove characters that could be intentional punctuation

---

## 10. PDF extraction damage detection

### 10.1 Common PDF extraction artifacts

PDF text extraction (via pdfplumber, PyMuPDF, etc.) introduces specific damage patterns that differ from OCR noise:

| Artifact | Description |
|---|---|
| **Ligature splitting** | Arabic ligatures (lam-alef, etc.) extracted as two separate characters with a space between them |
| **Hyphenation artifacts** | Words split across lines with a hyphen at the wrong position for Arabic |
| **Column merging errors** | Text from two columns merged into one stream, interleaving words from different columns |
| **Table content bleeding** | Table cell text extracted with cell separators embedded |
| **Bidi marker injection** | PDF extractors inject U+202A/U+202B/U+202C/U+202D/U+202E directional markers |
| **Font substitution artifacts** | Characters in a custom font mapping rendered as wrong Unicode code points |

### 10.2 Detection

PDF-damage-specific detection flags are a subset of the general quality report. They are identified by the same issue codes but the `source_hint` field in the issue object is set to `"pdf_extraction"` when the pattern matches a known PDF artifact.

### 10.3 Scope limitation

The pipeline does NOT re-extract text from PDFs. If a PDF extraction has a column merging error, the pipeline can detect the symptom (unusual word interleaving pattern) but cannot fix it — this requires re-extracting with better configuration. Such issues are flagged at `error` severity with a suggestion to re-extract.

---

## 11. Semantic chunking

### 11.1 Purpose

Chunking splits a long Arabic text into semantically coherent segments. Chunks are used for:
- LLM context windows (each chunk fits comfortably)
- Search indexing (each chunk is a meaningful unit)
- Document structure understanding

### 11.2 Arabic structural markers

The pipeline recognizes the following Arabic structural headings:

| Marker | Type | Example |
|---|---|---|
| `باب` | `chapter` | `الباب الأول: في العقود` |
| `فصل` | `section` | `الفصل الثاني` |
| `مبحث` | `topic` | `المبحث الأول: في الإيجاب` |
| `مطلب` | `subtopic` | `المطلب الثاني` |
| Numbered Arabic headings | `section` | `أولاً:`, `ثانياً:`, `ثالثاً:` |
| Numbered Western headings | `section` | `1.`, `1.1`, `1.1.1` |

### 11.3 Hierarchy

Chunking produces a flat list of chunks, not a nested tree. Each chunk records its `type` to indicate hierarchy level. Callers that need a tree can reconstruct it from types.

Hierarchy order (high to low):
`book` > `chapter` > `section` > `topic` > `subtopic` > `paragraph`

### 11.4 Chunk cohesion rules

- Short paragraphs (fewer than MIN_PARAGRAPH_CHARS characters, default 100) that are not headings are merged with the preceding chunk.
- A heading with no following body text becomes a chunk with empty `text` field.
- A block of text with no recognized heading is chunked as `paragraph` type.
- `start_index` and `end_index` refer to character positions in the **input** text (not the repaired text).

### 11.5 What chunking does NOT do

- Does not translate headings
- Does not produce summaries
- Does not reorder content
- Does not remove headings from the body text (heading text appears both in `title` and in `text`)

---

## 12. LLM preparation

### 12.1 Purpose

LLM preparation produces a final output object ready for ingestion by a language model or search engine. It runs quality analysis, optional repair, and chunking, then assembles the result.

### 12.2 Search keys

When `produce_search_key=True`:
- `search_key` — a normalized version of the text with tashkeel removed, tatweel removed, and whitespace normalized. Used for exact/fuzzy search.
- `loose_search_key` — additionally removes common function words and collapses repeated characters. Used for broad semantic search.

Both keys are derived from the **repaired** text (or original if no repair was performed), never from `original_text` directly.

### 12.3 Warnings

The output includes a `warnings` list. This is distinct from quality issues:
- Quality issues describe the input text
- Warnings describe actions the pipeline took or declined to take

Examples of warnings:
- `"unsafe_repair_skipped: AQ003_POSSIBLY_REVERSED"`
- `"tashkeel_preserved: quran_text_detected"`
- `"chunk_count_high: 47 chunks produced — consider increasing MIN_PARAGRAPH_CHARS"`

### 12.4 Metadata summary

The output includes a `metadata` object:

```json
{
  "char_count": 1234,
  "arabic_char_count": 987,
  "arabic_ratio": 0.82,
  "chunk_count": 7,
  "quality": "warning",
  "pipeline_version": "0.1.0"
}
```

---

## 13. Output object shapes

### 13.1 QualityIssue

```json
{
  "code": "AQ001_EXCESSIVE_TATWEEL",
  "description": "Text contains excessive tatweel (kashida) characters used for visual stretching.",
  "severity": "warning",
  "count": 12,
  "span": [4, 8],
  "source_hint": null
}
```

Fields:
- `code` (str, required) — issue code from §5.2
- `description` (str, required) — human-readable explanation
- `severity` (str, required) — `"info"`, `"warning"`, or `"error"`
- `count` (int, optional) — how many instances were found
- `span` (list[int, int] | null, optional) — character range of first occurrence
- `source_hint` (str | null, optional) — `"ocr"`, `"pdf_extraction"`, or null

### 13.2 QualityReport

```json
{
  "quality": "warning",
  "arabic_ratio": 0.91,
  "issues": [
    { "code": "AQ001_EXCESSIVE_TATWEEL", "..." : "..." }
  ]
}
```

### 13.3 RepairSuggestion

```json
{
  "type": "reverse_text",
  "reason": "AQ003_POSSIBLY_REVERSED",
  "description": "The text may be visually reversed. Manual review recommended.",
  "safe": false
}
```

### 13.4 RepairResult

```json
{
  "original_text": "...",
  "repaired_text": "...",
  "changed": true,
  "issues_fixed": ["AQ001_EXCESSIVE_TATWEEL"],
  "suggestions": []
}
```

### 13.5 Chunk

```json
{
  "title": "الفصل الأول",
  "type": "section",
  "text": "الفصل الأول\nنص الفصل هنا...",
  "start_index": 0,
  "end_index": 123
}
```

Chunk types: `"book"`, `"chapter"`, `"section"`, `"topic"`, `"subsection"`, `"paragraph"`

### 13.6 PipelineOutput

```json
{
  "original_text": "...",
  "clean_text": "...",
  "quality_report": {},
  "chunks": [],
  "search_key": "...",
  "loose_search_key": "...",
  "warnings": [],
  "metadata": {
    "char_count": 1234,
    "arabic_char_count": 987,
    "arabic_ratio": 0.82,
    "chunk_count": 7,
    "quality": "warning",
    "pipeline_version": "0.1.0"
  }
}
```

---

## 14. Fixture format

### 14.1 General structure

Each fixture file is a JSON object with a `"cases"` array:

```json
{
  "fixture_version": "0.1.0",
  "cases": []
}
```

### 14.2 Case structure

Every case MUST have:
- `id` (str) — unique, kebab-case or dash-separated, prefixed by file type (e.g. `quality-001`)
- `name` (str) — human-readable English name
- `input` (str | object) — the input to the function under test
- `expected` (object) — the expected output or properties of the output

### 14.3 Fixture versioning

The `fixture_version` field tracks the spec version when the fixture was written. When the spec changes in a breaking way, all fixtures must be reviewed and their versions updated.

### 14.4 Fixture determinism

All fixture inputs and expected outputs MUST be deterministic: the same input always produces the same output. Fixtures that depend on random state, system time, or external resources are forbidden.

---

## 15. Contribution rules

### 15.1 Adding a new issue code

1. Add the code to the table in §5.2
2. Define detection method precisely
3. Add at least two fixtures to `quality.json`: one that triggers the issue, one that does not
4. Update `SPEC_VERSION`

### 15.2 Adding a new repair

1. Classify it as safe or unsafe (§7)
2. Add to the appropriate table in §7.1 or §7.2
3. Add at least two fixtures to `repair.json`: one where repair applies, one where it must not
4. If unsafe, add a fixture showing the suggestion output

### 15.3 Adding a new chunk type

1. Add to the table in §11.2
2. Add at least one fixture to `chunking.json`
3. Confirm hierarchy position in §11.3

### 15.4 Fixture review

Every new fixture case must be reviewed by a second author before merge. The reviewer checks:
- Input is realistic (derived from or similar to real Arabic text)
- Expected output is correct
- The case tests exactly one behavior (no compound cases)
- No personally identifiable information in fixture inputs

### 15.5 Breaking changes

Changes to output object shapes (§13), issue codes (§5.2), or quality levels (§5.1) are breaking changes and require a `SPEC_VERSION` minor bump and changelog entry.

---

## 16. Open questions

| # | Question | Status |
|---|---|---|
| OQ-001 | Should `arabic_ratio` count only base Arabic letters, or include all Arabic Unicode ranges (including diacritics, presentation forms)? | Open |
| OQ-002 | Should tashkeel removal be a safe repair by default for non-Quranic text, or always unsafe? | Open |
| OQ-003 | What is the correct minimum chunk size for LLM token windows? Should MIN_PARAGRAPH_CHARS be defined in terms of characters or estimated tokens? | Open |
| OQ-004 | How should the pipeline handle mixed Arabic/Persian/Urdu text? All use the Arabic script but have different normalization rules. | Open |
| OQ-005 | Should the pipeline attempt to detect and label Quranic verses specifically, or treat them as dense-tashkeel Arabic? | Open |
| OQ-006 | Is `loose_search_key` generation in scope for 0.1.0, or deferred? | Open |
| OQ-007 | Should chunking attempt to detect numbered lists and handle them as sub-chunks, or treat list items as paragraph chunks? | Open |
| OQ-008 | Column merging errors from PDF extraction cannot be fixed without re-extraction — should the pipeline expose a `re_extract_hint` field with suggested extractor settings? | Open |
