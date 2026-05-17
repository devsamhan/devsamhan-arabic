# arabic_text_pipeline

A Python-first Arabic text quality and preprocessing pipeline. **v0.1.0 complete.**

## What this package does

This package is a **post-extraction** Arabic text pipeline. It receives already-extracted Arabic text and improves, analyzes, and prepares it for downstream use.

It works **after** OCR or PDF extraction — it does not perform OCR, does not parse PDFs, and does not replace tools like PaddleOCR, PyMuPDF, pdfplumber, or Tesseract.

## Where it fits

```
[Image / PDF file]
       ↓
[OCR engine / PDF extractor]   ← NOT this package
       ↓
[Raw extracted Arabic text]
       ↓
[arabic_text_pipeline]         ← THIS package
       ↓
[Clean text | Quality report | Semantic chunks | LLM-ready output]
```

## Non-goals

- Does not parse PDF files
- Does not run OCR on images
- Does not replace PaddleOCR, PyMuPDF, pdfplumber, or Tesseract
- Does not summarize or semantically understand text
- Does not make AI or LLM API calls

## Python v0.1.0 — implemented APIs

| Function | Description |
|---|---|
| `analyze_quality(text)` | Quality analysis with named issue codes (AQ001–AQ007) |
| `repair_text(text)` | Conservative safe repairs; unsafe issues as suggestions only |
| `chunk_semantic(text)` | Split by Arabic structural headings (باب، فصل، مبحث…) |
| `prepare_for_llm(text, ...)` | Full pipeline: repair → clean → quality → chunks → metadata |

```python
from devsamhan_arabic_text_pipeline import prepare_for_llm

result = prepare_for_llm(text, include_search_key=True)
# result["clean_text"]     → repaired and normalised text
# result["quality_report"] → quality level and issue list
# result["chunks"]         → semantic chunks with positions
# result["metadata"]       → counts, ratios, quality, pipeline_version
# result["warnings"]       → actionable warning strings
```

## Design philosophy

- **Never silently destroy the original.** `original_text` is always preserved.
- **Repair output is separate.** Repaired text lives in `repaired_text`, never overwriting input.
- **Unsafe repairs are suggestions only.** Reversed-text and separated-letter repairs are flagged, never forced.
- **Quality reports are explainable.** Every issue has a named code and human-readable description.
- **Conservative by default.** When in doubt, preserve.

## Spec-first / fixture-first design

All behavior is defined in [`test_fixtures/`](test_fixtures/) before implementation:

| Fixture file | Covers |
|---|---|
| `test_fixtures/quality.json` | 12 quality analysis cases |
| `test_fixtures/repair.json` | 14 repair behavior cases |
| `test_fixtures/chunking.json` | 10 semantic chunking cases |
| `test_fixtures/llm_prep.json` | 12 LLM preparation cases |

See [`test_fixtures/SPEC.md`](test_fixtures/SPEC.md) for the full behavioral specification.

## Python package

See [`python/README.md`](python/README.md) for installation, full API documentation, and usage examples.
