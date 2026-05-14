# devsamhan-arabic — Behavioral Specification

**SPEC_VERSION: 1.0.0**

This file is the authoritative behavioral contract for all implementations
of devsamhan-arabic (`arabic_text`). Every port — Dart, TypeScript, Python —
must produce identical output for each fixture case. The fixture JSON files
are the ground truth; this document explains the reasoning behind each
decision.

---

## Purpose

Provide Arabic text normalization that is:

- Consistent across programming languages and platforms.
- Safe for database indexing and full-text search.
- Predictable: identical input always produces identical output.
- Minimal: each function does exactly one thing; presets compose them
  in a documented, fixed order.

---

## Philosophy

1. **Fixtures first.** The JSON fixture files define correctness. Code is an
   implementation; fixtures are the contract. Any discrepancy between code and
   fixtures must be resolved by fixing the code.

2. **Conservative by default.** Normalization that could corrupt meaning is
   never applied silently. Functions that change semantics (e.g.,
   `normalizeTaMarbouta`) are explicit-only and must be called directly.

3. **Preserve what you cannot reconstruct.** Once ة is converted to ه,
   the original spelling is lost. `toSearchKey` therefore preserves ة; only
   `toLooseSearchKey` and `toSlug` convert it, and callers opt in knowingly.

4. **Encoding artifacts vs. linguistic choices.** Persian Yeh (ی U+06CC)
   in Arabic text is an encoding artifact from Persian-layout keyboards.
   Alef Maqsoura (ى U+0649) is a distinct Arabic letter used in formal
   spelling. These require different treatment.

5. **This is not a collation library.** `sort()` provides stable, consistent
   ordering across implementations. It is not a substitute for ICU,
   locale-aware collation, or full Unicode Collation Algorithm (UCA)
   compliance. Do not claim otherwise.

---

## Definitions

| Term | Definition |
|---|---|
| **Tashkeel** | Short vowel diacritics: fatha (َ), damma (ُ), kasra (ِ), shadda (ّ), sukun (ْ), tanwin forms (ً ٌ ٍ), and related marks (U+064B–U+065E, U+0670). |
| **Tatweel** | The horizontal stretch character U+0640 (ـ), used for visual stretching only. |
| **Alef variants** | أ (U+0623), إ (U+0625), آ (U+0622), ٱ (U+0671) — all normalize to bare ا (U+0627). |
| **Alef Maqsoura** | ى (U+0649) — a distinct Arabic letter, NOT an alef variant. |
| **Persian Yeh** | ی (U+06CC) — visually similar to ي but a different codepoint; treated as an encoding artifact in Arabic text. |
| **Ta Marbouta** | ة (U+0629) — feminine ending; semantically meaningful. Preserved in conservative presets. |
| **Presentation Forms** | Legacy Arabic shapes in blocks FB50–FDFF (Forms-A) and FE70–FEFF (Forms-B). Must be decomposed to canonical codepoints before any other normalization. |
| **Search key** | A normalized string intended for database storage and full-text search indexing. Not for display. |
| **Sort key** | A normalized string used as the comparator key for ordering. Derived from `toSearchKey` with ة preserved. |
| **Loose search key** | An aggressively normalized string used for query-side matching. More variants map to the same key. |

---

## Processing Order

When multiple normalizations are composed (as in `toSearchKey`), they must be
applied in this exact order. Applying them out of order produces incorrect
results.

| Step | Function | Notes |
|---|---|---|
| 1 | `normalizePresentationForms` | Must run first. Presentation-form codepoints would otherwise be missed by letter-level normalizations. |
| 2 | `removeTatweel` | Remove U+0640 stretch characters. |
| 3 | `removeTashkeel` | Remove diacritics. After tatweel removal so stretch-plus-diacritic sequences are handled correctly. |
| 4 | `normalizeAlef` | Normalize alef variants (أ إ آ ٱ → ا). After tashkeel removal to avoid hamza-carrier confusion. |
| 5 | `normalizeHamza` | Normalize ؤ → ء and ئ → ء. After alef normalization (alef-hamza forms are handled by step 4). |
| 6 | `normalizeYa` | Normalize ى → ي and ی → ي. |
| 7 | `normalizeTaMarbouta` | **Explicit-only.** Not called in `toSearchKey`. Called in `toLooseSearchKey`, `toSlug`, and when the caller opts in. |
| 8 | `normalizeDigits` | **Explicit-only.** Requires a `to` option (`"western"` or `"eastern"`). Not called in any preset. |
| 9 | Whitespace collapse | Trim leading/trailing whitespace; collapse internal runs of whitespace (spaces, tabs, newlines) to a single space. |

---

## Presets

Presets are fixed compositions of surgical functions. Their pipelines must not
be altered without a `SPEC_VERSION` bump.

### `toSearchKey(text)`

**Purpose:** Primary normalization for database indexing and full-text search.
Store the result; index on it; search by comparing two search keys.

**Pipeline:** steps 1–6 + step 9 (whitespace collapse).

**Explicit exclusions:**
- `normalizeTaMarbouta` is NOT applied. ة is preserved.
- `normalizeDigits` is NOT applied. Eastern Arabic digits and Latin digits
  are preserved as-is. Callers who need digit normalization must call it
  separately.
- Punctuation is NOT removed.
- Latin text passes through unchanged (beyond whitespace collapsing).

**Key behaviors (verified in `search_key.json`):**

| Input | Output | Reason |
|---|---|---|
| `فَاطِمَةُ` | `فاطمة` | ة preserved |
| `موسى` | `موسي` | ى → ي (step 6) |
| `مسؤول` | `مسءول` | ؤ → ء (step 5) |
| `علی` | `علي` | ی → ي (step 6) |
| `السعر ١٢٥ ريال` | `السعر ١٢٥ ريال` | digits untouched |
| `ﻣﺮﺣﺒﺎ` | `مرحبا` | presentation forms normalized |
| `Invoice فاتورة` | `Invoice فاتورة` | Latin preserved |

---

### `toLooseSearchKey(text)`

**Purpose:** Query-side normalization. More variants map to the same key.
Use this to normalize a user's search query, not for storage.

**Pipeline:** all of `toSearchKey` + `normalizeTaMarbouta` (step 7).

**Key difference from `toSearchKey`:** ة → ه.

| Input | toSearchKey | toLooseSearchKey |
|---|---|---|
| `فَاطِمَةُ` | `فاطمة` | `فاطمه` |
| `مَكَّةُ المُكَرَّمَة` | `مكة المكرمة` | `مكه المكرمه` |

**Usage pattern:** index documents using `toSearchKey`; normalize queries using
`toLooseSearchKey`. Searching `فاطمه` against an index of `فاطمة` will match
because both normalize to the same loose key.

---

### `toDisplayKey(text)`

**Purpose:** Light cleanup for display. Makes text visually consistent without
altering semantics.

**Pipeline:** `normalizePresentationForms` + `removeTatweel` only.

**Preserves:** tashkeel, alef variants, hamza, ة, ى, digits — everything
except tatweel and presentation forms.

| Input | Output |
|---|---|
| `مـُحَمَّد` | `مُحَمَّد` (tatweel removed, tashkeel kept) |
| `أَحْمَد` | `أَحْمَد` (untouched) |
| `مـحـمـد @email.com` | `محمد @email.com` |

---

### `toSlug(text)`

**Purpose:** Generate URL-safe slugs from Arabic text.

**Pipeline:** `toSearchKey` steps + `normalizeTaMarbouta` + spaces → hyphens
+ Latin lowercased + leading/trailing hyphens trimmed.

**Key behaviors:**

| Input | Output |
|---|---|
| `مدينة الرياض` | `مدينه-الرياض` |
| `مُحَمَّد الأحمد` | `محمد-الاحمد` |
| `مدرسة` | `مدرسه` |
| `تطبيق App` | `تطبيق-app` |

Note: ة → ه in slug (unlike `toSearchKey`). Latin is lowercased.

---

### `normalizeName(text)`

**Purpose:** Canonical form for storing proper names. Strips noise
(tashkeel, tatweel, presentation forms, alef variants, Persian Yeh) while
preserving linguistically meaningful distinctions.

**Pipeline:** `normalizePresentationForms` + `removeTatweel` + `removeTashkeel`
+ `normalizeAlef` + normalize Persian Yeh only (ی → ي) + whitespace collapse.

**Key distinctions from `toSearchKey`:**

| Character | `toSearchKey` | `normalizeName` | Reason |
|---|---|---|---|
| ى (U+0649 Alef Maqsoura) | → ي | **preserved** | Linguistically meaningful in names (موسى, يحيى) |
| ی (U+06CC Persian Yeh) | → ي | → ي | Encoding artifact, not a linguistic choice |
| ة (U+0629 Ta Marbouta) | preserved | preserved | Both presets preserve ة |

| Input | Output |
|---|---|
| `مُحَمَّد` | `محمد` |
| `فَاطِمَةُ` | `فاطمة` |
| `موسى` | `موسى` (ى preserved) |
| `مهدی` | `مهدي` (ی normalized) |
| `يحيى` | `يحيى` (both ى preserved) |

---

### `toSortKey(text)`

**Purpose:** Generate the comparator key used by `sort()` and `compare()`.

**Pipeline:** identical to `toSearchKey` (steps 1–6 + whitespace collapse).
ة is preserved in sort keys; `normalizeTaMarbouta` is not applied.

---

## Surgical Functions

Individual atomic functions. Each does exactly one thing.

| Function | Input → Output | Scope |
|---|---|---|
| `removeTashkeel(text)` | Strips U+064B–U+065E, U+0670 | All Arabic diacritics |
| `removeTatweel(text)` | Strips U+0640 | Stretch character only; U+0670 is tashkeel, not tatweel |
| `normalizeAlef(text)` | أ إ آ ٱ → ا | Alef variants only; does not touch ى |
| `normalizeHamza(text)` | ؤ → ء, ئ → ء | Hamza seats only; alef-hamza forms handled by `normalizeAlef` |
| `normalizePresentationForms(text)` | FB50–FDFF, FE70–FEFF → canonical | Decomposes legacy Arabic shapes |
| `normalizeYa(text)` | ى → ي, ی → ي | Both Alef Maqsoura and Persian Yeh |
| `normalizeTaMarbouta(text)` | ة → ه | **Explicit-only.** Never called automatically. |
| `normalizeDigits(text, options)` | Converts digit script | Requires `options.to` = `"western"` or `"eastern"` |

---

## `ArabicNormalizeOptions` / `normalizeDigits` options

`normalizeDigits` is the only surgical function that takes an options argument.

| Option | Values | Meaning |
|---|---|---|
| `to` | `"western"` | Convert Eastern Arabic (٠–٩) and Persian (۰–۹) digits to 0–9 |
| `to` | `"eastern"` | Convert Western (0–9) digits to Eastern Arabic (٠–٩) |

Non-digit characters pass through unchanged in both directions.

The function converts **all three digit scripts** (Western, Eastern Arabic,
Persian) to the target script when `"western"` is specified. When `"eastern"`
is specified, only Western digits are converted; Persian digits are also
converted to Eastern Arabic.

---

## What Must NOT Be Normalized by Default

The following are **never** applied in `toSearchKey`, `toSortKey`,
`normalizeName`, or `toDisplayKey` without explicit caller opt-in:

- **`normalizeTaMarbouta`** — converting ة to ه changes spelling and loses
  information. Applied only in `toLooseSearchKey`, `toSlug`, and explicit calls.

- **`normalizeDigits`** — digit script is not a spelling error. Applications
  control which digit script they store and display. `toSearchKey` preserves
  Eastern Arabic digits as-is (fixture `sk-mixed-003`).

- **Punctuation removal** — punctuation is structural. Stripping it blindly
  would corrupt file paths, IDs, and formatted numbers.

- **Definite article (ال) stripping** — stripping `ال` for sort requires
  locale knowledge and is not universally correct. Not applied in v1.

- **Case normalization of Latin text** — Latin characters are preserved
  exactly. `toSlug` is the only function that lowercases Latin, and only in
  that context.

---

## Numbers

### `normalizeDigits` function

Supports conversion between three digit scripts:

| Script | Range | Example |
|---|---|---|
| Western (ASCII) | U+0030–U+0039 | `0123456789` |
| Eastern Arabic | U+0660–U+0669 | `٠١٢٣٤٥٦٧٨٩` |
| Persian extended | U+06F0–U+06F9 | `۰۱۲۳۴۵۶۷۸۹` |

All three scripts are mutually convertible. Non-digit characters pass through.
The decimal separator (`.`) and thousands separator (`,`) are not converted.

### Digit normalization in presets

`toSearchKey` does **not** normalize digits. Eastern Arabic digits in a search
key remain as Eastern Arabic digits (fixture `sk-mixed-003`).

This is a deliberate decision: digit representation is a display and locale
concern, not a spelling normalization. Callers who need unified digit keys
must chain `normalizeDigits` before or after `toSearchKey` explicitly.

---

## Mixed Arabic/English Text

All normalization functions operate on the full Unicode string and must not
corrupt non-Arabic content.

**Invariants:**
- Latin letters pass through unchanged (except `toSlug` which lowercases them).
- ASCII digits pass through unchanged in all presets.
- Email addresses, file paths, IDs, and URLs embedded in Arabic text must
  survive normalization intact.
- Only characters in Arabic Unicode blocks are subject to Arabic normalization.

**Verified in fixtures:**

| Input | Function | Output |
|---|---|---|
| `Hello مُحَمَّد` | `removeTashkeel` | `Hello محمد` |
| `Invoice فاتورة` | `toSearchKey` | `Invoice فاتورة` |
| `طلب رقم 123` | `toSearchKey` | `طلب رقم 123` |
| `مـحـمـد @email.com` | `toDisplayKey` | `محمد @email.com` |
| `تطبيق App` | `toSlug` | `تطبيق-app` |

---

## Sorting

### `sort(list)` and `compare(a, b)`

`sort()` accepts a list of strings and returns a new list sorted by
`toSortKey`. The original strings are returned (not the sort keys).
The sort is **stable**: strings whose sort keys are identical retain their
original relative order.

`compare(a, b)` returns `-1`, `0`, or `1` using the same key comparison.

### What this is

- Consistent, reproducible ordering across all ports.
- Equivalent strings (hamza/alef/tashkeel variants) sort together.
- Stable: equal-keyed items preserve input order.

### What this is NOT

- **Not full Arabic dictionary collation.** The Arabic dictionary places
  root letters before derived forms and applies locale-specific rules
  (e.g., ث before ج, ignoring ال prefixes for indexing). This library
  does not implement that.
- **Not ICU/Unicode Collation Algorithm.** Do not claim UCA or
  CLDR-equivalent behavior.
- **No definite article stripping.** `الرياض` and `رياض` are different
  sort keys in v1. Full collation with article stripping may be added as
  `ArabicCollator` in v2.

### Sort key rules

- Derived via `toSearchKey` (steps 1–6 + whitespace).
- ة is **preserved** in sort keys. `فاطمة` and `فاطمه` produce different
  sort keys; they will not be grouped unless the caller normalizes first.
- Sort order for Arabic letters follows Unicode codepoint order of the
  normalized key (lexical, not phonetic/dictionary).

### Verified sort results (fixture `sorting.json`)

```
Input:  [يوسف, أحمد, إبراهيم, محمد, آدم]
Keys:   [يوسف, احمد, ابراهيم, محمد, ادم]
Sorted: [إبراهيم, أحمد, آدم, محمد, يوسف]
```

---

## Cross-Language Implementation Requirements

All ports must:

1. **Pass all fixture cases** with exact string/value equality.
2. **Implement API naming conventions:**
   - Dart: `camelCase` (e.g., `toSearchKey`, `normalizeAlef`)
   - TypeScript: `camelCase` (same as Dart)
   - Python: `snake_case` (e.g., `to_search_key`, `normalize_alef`)
3. **Expose `SPEC_VERSION`** as a constant string `'1.0.0'`.
4. **Implement the processing order** (§Processing Order) identically.
   Do not combine steps or change their sequence.
5. **Zero runtime dependencies** for `arabic_text`. The library must be
   self-contained.
6. **No behavior additions** without a fixture to cover them. If it is not in
   a fixture, it is not specified.

---

## Fixture File Format

```json
{
  "meta": {
    "spec_version": 1,
    "description": "...",
    "notes": "..."
  },
  "cases": [
    {
      "id": "unique-id",
      "name": "Human-readable description",
      "operation": "functionName",
      "input": "...",
      "expected": "...",
      "options": {},
      "notes": "Optional explanation"
    }
  ]
}
```

- `operation`: the exact function name in camelCase. Ports map this to their
  naming convention.
- `options`: present only for `normalizeDigits`.
- `input` for `sort` and `compare` operations is an array, not a string.
- `expected` for `sort` is an array; for `compare` is `-1`, `0`, or `1`;
  for `isArabic` is `true` or `false`; for `arabicRatio` is a float.

---

## Contribution Rules

1. **Read this file first.** Changes to behavior require a change here first.
2. **Fixtures are the contract.** A new normalization behavior requires a new
   fixture case before any code is written.
3. **Bump `SPEC_VERSION`** if any observable behavior changes for existing
   inputs. Do not bump for new cases that cover previously unspecified inputs.
4. **All ports must pass all fixtures** after any change. A change that
   breaks one port breaks the spec.
5. **`normalizeTaMarbouta` is explicit-only.** It must never appear in the
   pipeline of `toSearchKey`, `toSortKey`, or `normalizeName`.
6. **`normalizeDigits` is explicit-only.** It must never appear in any preset.
7. **Do not claim full BiDi or full collation.** `arabic_bidi` implements a
   simplified reshaping algorithm suitable for CLI/logs. `arabic_text` sorting
   is not full Arabic dictionary collation.
8. **Latin text must survive.** Any normalization that corrupts embedded
   Latin characters, digits, punctuation, or identifiers is a bug.

---

## Resolved Decisions

### Q1 — Persian Yeh (ی U+06CC)

**Decision:** Normalize ی → ي in `normalizeYa`, `toSearchKey`, `toSortKey`.
Preserve ى (Alef Maqsoura) in `normalizeName` but normalize it in
`toSearchKey` and `toSortKey`.

**Rationale:** Persian Yeh appears in Arabic text as an encoding artifact
from Persian-layout keyboards. It is not a distinct Arabic letter; normalizing
it eliminates spurious mismatches between users on different keyboard layouts.
Alef Maqsoura (ى) is a distinct Arabic letter used in formal spelling
(e.g., موسى, ليلى); `normalizeName` preserves it because renaming a person
is not normalization.

**Status:** Resolved. Fixtures: `ya-persian-001` through `ya-persian-004`,
`sk-persian-ya-001`, `sk-persian-ya-002`, `name-003`, `name-004`.

---

### Q4 — Scope of `normalizeHamza`

**Decision:** `normalizeHamza` converts only ؤ (U+0624) → ء and ئ (U+0626) → ء.
It does not touch hamza-on-alef forms (أ U+0623, إ U+0625, آ U+0622).
It does not perform contextual spelling correction (i.e., it does not infer
the "correct" hamza seat for a given word).

**Rationale:** Hamza seats on alef are already handled by `normalizeAlef`.
Inferring the correct hamza seat (e.g., whether مسئول should be مسؤول or
مسئول) requires morphological analysis that is outside the scope of this
library. `normalizeHamza` eliminates the ؤ/ئ vs ء distinction for search
purposes without attempting to spell-correct.

**Status:** Resolved. Fixtures: `hamza-001` through `hamza-004`,
`sk-hamza-001`, `sk-hamza-002`.

---

## Open Questions

### Q2 — `toSearchKey` digit normalization

**Question:** Should `toSearchKey` optionally accept a flag to normalize
Eastern Arabic and Persian digits to Western digits in one call?

**Current behavior:** Digits are never normalized in `toSearchKey`. Callers
must call `normalizeDigits` separately. This means a document indexed with
`١٢٣` will not match a query for `123` unless both sides are digit-normalized.

**Arguments for:** Eliminates a common caller mistake; most full-text search
callers want unified digit keys.

**Arguments against:** Digit script is a locale decision, not a spelling
normalization. An application may legitimately want to preserve and index
Eastern Arabic digits.

**Status:** Unresolved for v1. Callers must normalize digits explicitly.

---

### Q3 — Definite article stripping in sort

**Question:** Should `toSortKey` strip the definite article `ال` for sort
purposes, so that `الرياض` sorts as if it were `رياض`?

**Current behavior:** `ال` is preserved in sort keys. `الرياض` and `رياض`
produce different sort keys and sort in different positions.

**Arguments for:** Arabic dictionaries and phonebooks traditionally sort
names by their root letters, ignoring the definite article.

**Arguments against:** Article stripping requires knowing whether `ال` is
truly a definite article or part of the word (e.g., `الله`, `إيلا`). Naive
stripping of leading `ال` produces wrong results for some words. A correct
implementation requires morphological analysis or a whitelist.

**Status:** Unresolved for v1. May be addressed in `ArabicCollator` (v2).
