# devsamhan-arabic-text-pipeline

**v0.1.0** — Python package for Arabic text quality analysis, conservative repair, semantic chunking, and LLM preparation.

## What this package does

A **post-extraction** Arabic text pipeline. It receives already-extracted Arabic text (from OCR, PDF tools, APIs, or databases) and:

- Analyzes text quality with named, explainable issue codes
- Applies conservative safe repairs automatically
- Flags unsafe repairs (reversed text, separated letters) as suggestions — never forces them
- Splits text into semantic chunks using Arabic structural headings
- Produces clean, quality-reported, LLM-ready output in one call

## What this package does NOT do

- **Does not parse PDF files** — use pdfplumber, PyMuPDF, or similar tools first
- **Does not run OCR** — use PaddleOCR, Tesseract, or similar tools first
- **Does not summarize or semantically understand text** — purely deterministic
- **Does not make AI or LLM API calls** — fully offline

## Where it fits

```
[Image / PDF file]
       ↓
[OCR engine / PDF extractor]   ← pdfplumber, PaddleOCR, PyMuPDF, Tesseract
       ↓
[Raw extracted Arabic text]
       ↓
[arabic_text_pipeline]         ← THIS package
       ↓
[Clean text | Quality report | Semantic chunks | LLM-ready output]
```

## Installation

```bash
pip install devsamhan-arabic-text-pipeline
```

For development:

```bash
pip install "devsamhan-arabic-text-pipeline[dev]"
```

## API

### analyze_quality

Analyze the quality of Arabic text. Returns a quality level and a list of named issues.

```python
from devsamhan_arabic_text_pipeline import analyze_quality

result = analyze_quality("مـحـمـد بن عبد الله")

# result["quality"]      → "warning"
# result["arabic_ratio"] → 0.9231
# result["issues"]       → [{"code": "AQ001_EXCESSIVE_TATWEEL", "severity": "medium", ...}]
# result["original_text"]→ "مـحـمـد بن عبد الله"
```

Issue codes: `AQ001_EXCESSIVE_TATWEEL`, `AQ002_TASHKEEL_DENSE`, `AQ003_POSSIBLY_REVERSED`,
`AQ004_SEPARATED_LETTERS`, `AQ005_MIXED_DIGITS`, `AQ006_OCR_NOISE`, `AQ007_LOW_ARABIC_RATIO`

Quality levels: `"good"` / `"warning"` / `"poor"`

### repair_text

Apply conservative repairs. Safe repairs are applied automatically; unsafe ones become suggestions only.

```python
from devsamhan_arabic_text_pipeline import repair_text

result = repair_text("مـحـمـد   بـن   عـبـد   الله")

# result["repaired_text"] → "محمد بن عبد الله"
# result["changed"]       → True
# result["issues_fixed"]  → ["AQ001_EXCESSIVE_TATWEEL"]
# result["suggestions"]   → []   # no unsafe issues detected
# result["original_text"] → "مـحـمـد   بـن   عـبـد   الله"
```

Safe repairs applied automatically:
- Tatweel (kashida) removal from Arabic words
- Zero-width character removal (ZWSP, ZWNJ, ZWJ, BOM)
- Bidi directional mark removal
- Trailing whitespace and CRLF normalisation
- Multiple consecutive spaces collapsed to one

Unsafe repairs returned as suggestions only (never applied):
- `reverse_text` — when text appears visually reversed
- `merge_separated_letters` — when Arabic letters appear broken apart

### chunk_semantic

Split Arabic text into semantic chunks based on structural headings.

```python
from devsamhan_arabic_text_pipeline import chunk_semantic

text = """الباب الأول: في أحكام العقود
العقد هو ارتباط إيجاب بقبول على وجه مشروع.

الباب الثاني: في أحكام البيع
البيع هو تمليك مال بمال على وجه التراضي."""

chunks = chunk_semantic(text)
# [
#   {"title": "الباب الأول: في أحكام العقود", "type": "chapter",
#    "text": "...", "start_index": 0, "end_index": 65},
#   {"title": "الباب الثاني: في أحكام البيع", "type": "chapter",
#    "text": "...", "start_index": 67, "end_index": 133},
# ]
```

Detected heading types and their chunk types:

| Arabic keyword | Chunk type |
|---|---|
| الكتاب / كتاب | `book` |
| الباب / باب | `chapter` |
| الفصل / فصل | `section` |
| المبحث / مبحث | `topic` |
| المطلب / مطلب | `subtopic` |
| أولاً / ثانياً / … | `section` |
| *(no headings)* | `paragraph` |

`start_index` and `end_index` always refer to positions in the original input string, so `text[start_index:end_index] == chunk["text"]`.

### prepare_for_llm

Full pipeline in one call: repair → clean → quality report → chunks → optional search keys → warnings.

```python
from devsamhan_arabic_text_pipeline import prepare_for_llm

result = prepare_for_llm(
    text,
    include_search_key=True,
    include_loose_search_key=False,
    apply_repair=True,          # default
)

# result["original_text"]   → unchanged input
# result["clean_text"]      → repaired + normalised text
# result["quality_report"]  → from analyze_quality()
# result["repair_report"]   → from repair_text(), or None if apply_repair=False
# result["chunks"]          → from chunk_semantic()
# result["search_key"]      → tashkeel-stripped clean_text (or None)
# result["loose_search_key"]→ further normalised for broad search (or None)
# result["warnings"]        → list of warning strings
# result["metadata"]        → char_count, arabic_char_count, arabic_ratio,
#                             chunk_count, quality, issue_count,
#                             changed, pipeline_version
```

Warnings generated automatically:
- `"empty_text"` — input is empty or whitespace-only
- `"poor_quality"` — quality level is `"poor"`
- `"unsafe_repair_skipped"` — repair found suggestions it could not safely apply
- `"tashkeel_preserved"` — dense diacritics were kept (AQ002 detected)

## Conservative repair philosophy

The pipeline **never silently modifies or destroys the original text.** `original_text` is always returned unchanged. All repairs live in `repaired_text` or `clean_text`.

Unsafe repairs — reversing visually-reversed text, merging broken letters — are returned as **suggestions only** in `repair_report["suggestions"]`. They are never applied automatically because both operations are context-dependent and can corrupt valid text if applied incorrectly.

## Requirements

- Python >= 3.9
- No runtime dependencies

## Development

```bash
python -m venv .venv
source .venv/bin/activate        # Linux/macOS
.venv\Scripts\activate           # Windows

pip install -e ".[dev]"
python -m pytest tests/ -v
```

## Specification

See [`../test_fixtures/SPEC.md`](../test_fixtures/SPEC.md) for the full behavioral specification including quality issue codes, repair policy, chunking rules, and output shapes.

All behavior is fixture-driven: [`../test_fixtures/`](../test_fixtures/) contains JSON test cases that define the expected behavior of every public function.
