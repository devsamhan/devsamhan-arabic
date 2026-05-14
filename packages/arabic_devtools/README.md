# @devsamhan/arabic-devtools

CLI toolkit for Arabic-aware development workflows.

## Installation

```bash
npm install -g @devsamhan/arabic-devtools
```

## Commands

### check-rtl \<path\>

Detect potentially reversed Arabic literals in a file.

```bash
arabic-devtools check-rtl src/strings.txt
```

Confidence levels:
- **HIGH** — known reversal dictionary (e.g. `ثحب` → `بحث`, `دمحم` → `محمد`)
- **MEDIUM** — word starts with `ة` (taʾ marbūṭa)
- **LOW** — word ends with `لا`

Exit code 1 if findings; 0 if clean.

### scan \<path\>

Scan a file or directory for Arabic text quality issues:
- Tatweel (`ـ`) in text
- Tashkeel (diacritics) in text
- Mixed Eastern + Western Arabic digits in the same line
- Potentially reversed RTL words

```bash
arabic-devtools scan src/
```

Exit code 1 if findings; 0 if clean.

### bidi "\<text\>"

Prepare Arabic text for correct terminal rendering (BiDi + reshaping).

```bash
arabic-devtools bidi "مرحبا بالعالم"
```

Always exits 0 (unless missing argument).

## License

MIT
