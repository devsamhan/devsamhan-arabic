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

**Text output** (default):
```
src/strings.txt:12:18 [AR001/high] "ثحب" → بحث — Potentially reversed Arabic literal
```

**JSON output**:
```bash
arabic-devtools check-rtl src/strings.txt --format json
```
```json
{
  "tool": "arabic-devtools",
  "command": "check-rtl",
  "findings": [
    {
      "code": "AR001",
      "type": "potentially-reversed-arabic-literal",
      "severity": "high",
      "file": "src/strings.txt",
      "line": 12,
      "column": 18,
      "found": "ثحب",
      "suggestion": "بحث",
      "message": "Potentially reversed Arabic literal"
    }
  ]
}
```

**Severity threshold** — show only high-severity findings:
```bash
arabic-devtools check-rtl src/strings.txt --severity-threshold high
```

Exit code 1 if findings; 0 if clean.

---

### scan \<path\>

Scan a file or directory for Arabic text quality issues:
- Tatweel (`ـ`) in text (AR002)
- Tashkeel (diacritics) in text (AR003)
- Mixed Eastern + Western Arabic digits on the same line (AR004)
- Potentially reversed RTL words (AR001)

```bash
arabic-devtools scan src/
arabic-devtools scan src/ --format json
arabic-devtools scan src/ --severity-threshold medium
```

In CI:
```bash
arabic-devtools scan . --format json
```

Exit code 1 if findings; 0 if clean.

---

### bidi "\<text\>"

Prepare Arabic text for correct terminal rendering (BiDi + reshaping).

```bash
arabic-devtools bidi "مرحبا بالعالم"
```

Always exits 0 (unless missing argument).

---

## Rules

| Code | Rule | Severity |
|------|------|----------|
| AR001 | potentially-reversed-arabic-literal | high / medium / low |
| AR002 | excessive-tatweel | medium |
| AR003 | tashkeel-in-search-key | medium |
| AR004 | mixed-digit-scripts | low |

All findings are diagnostic only — no automatic fixes are applied.

See [docs/rules.md](docs/rules.md) for full documentation including examples and
recommendations for each rule.

## License

MIT
