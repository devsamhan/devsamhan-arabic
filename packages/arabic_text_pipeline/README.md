# arabic_text_pipeline

A Python-first Arabic text quality and preprocessing pipeline.

## What this package does

This package is a **post-extraction** Arabic text pipeline. It receives already-extracted Arabic text and improves, analyzes, and prepares it for downstream use.

It works **after** OCR or PDF extraction has already occurred — it does not perform OCR, does not parse PDF files, and does not replace tools like PaddleOCR, PyMuPDF, pdfplumber, or Tesseract.

## What this package does NOT do

- Parse PDF files
- Run OCR on images
- Replace PaddleOCR, PyMuPDF, pdfplumber, or Tesseract
- Perform any document image processing

## Where it fits

```
[Image / PDF file]
       ↓
[OCR engine / PDF extractor]   ← NOT this package
       ↓
[Raw extracted text]
       ↓
[arabic_text_pipeline]         ← THIS package
       ↓
[Clean text, quality report, chunks, LLM-ready output]
```

## Relationship to arabic_text

This package depends conceptually on `arabic_text` (the base Arabic utility library in this monorepo), but does not replace it. `arabic_text` provides fundamental character-level utilities (Unicode normalization, letter detection, tatweel handling). This pipeline builds higher-level analysis, repair, and chunking on top of those primitives.

## Inputs

- Raw Arabic text from an OCR engine
- Raw text extracted from a PDF
- Text copied from a document or web page
- Text received from an API or database

## Outputs

- **Cleaned text** — normalized, repaired where safe
- **Quality report** — scored analysis with named issue codes
- **Repair suggestions** — for issues that are unsafe to auto-repair
- **Semantic chunks** — split by Arabic structural headings (باب، فصل، مبحث...)
- **Search/LLM-ready text** — normalized text with optional search keys and metadata

## Design philosophy

- **Never silently destroy the original.** `original_text` is always preserved.
- **Repair output is separate from original.** Repaired text lives in `repaired_text`, never overwriting input.
- **Unsafe repairs are suggestions only.** The pipeline flags, never forces, ambiguous changes.
- **Quality reports are explainable.** Every issue has a named code, a human-readable description, and an affected span where possible.
- **Arabic repair is conservative by default.** When in doubt, preserve.

## Python package

See [`python/README.md`](python/README.md) for installation and usage.

## Specification and fixtures

See [`test_fixtures/SPEC.md`](test_fixtures/SPEC.md) for the full behavioral specification.
