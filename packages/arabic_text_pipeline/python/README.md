# devsamhan-arabic-text-pipeline

Python package for Arabic text quality analysis, repair, semantic chunking, and LLM preparation.

**Status:** Phase 1 — spec and fixtures only. Implementation pending.

## What this is

A post-extraction Arabic text pipeline. It receives already-extracted Arabic text (from OCR, PDF extraction, copy-paste, or APIs) and:

- Analyzes text quality with named issue codes
- Applies safe repairs conservatively
- Suggests unsafe repairs without applying them
- Splits text into semantic chunks using Arabic structural headings
- Produces LLM-ready and search-ready output

This package does **not** parse PDFs or run OCR.

## Requirements

- Python >= 3.9
- No runtime dependencies

## Installation

```bash
pip install devsamhan-arabic-text-pipeline
```

For development:

```bash
pip install "devsamhan-arabic-text-pipeline[dev]"
```

## Current API

```python
from devsamhan_arabic_text_pipeline import SPEC_VERSION

print(SPEC_VERSION)  # "0.1.0"
```

All pipeline functions (`analyze_quality`, `repair`, `chunk`, `prepare_for_llm`) are planned for Phase 2 implementation.

## Specification

See [`../test_fixtures/SPEC.md`](../test_fixtures/SPEC.md) for the full behavioral specification including quality issue codes, repair policy, chunking rules, and output shapes.

## Fixture files

| File | Purpose |
|---|---|
| `../test_fixtures/quality.json` | Quality analysis test cases |
| `../test_fixtures/repair.json` | Repair behavior test cases |
| `../test_fixtures/chunking.json` | Semantic chunking test cases |
| `../test_fixtures/llm_prep.json` | LLM preparation test cases |

## Development

```bash
python -m venv .venv
source .venv/bin/activate        # Linux/macOS
.venv\Scripts\activate           # Windows

pip install -e ".[dev]"
python -m pytest tests/ -v
```
