# arabic-devtools Rule Reference

All findings are **diagnostic only**. No automatic fixes are applied.

---

## AR001 — potentially-reversed-arabic-literal

**Purpose**: Detect Arabic words that may have been accidentally entered or stored in
right-to-left visual order instead of Unicode logical order — a common mistake when text
is typed in environments without proper BiDi support.

**Severity**:
- `high` — word matches the known-reversal dictionary (high confidence)
- `medium` — word starts with `ة` (taʾ marbūṭa), which never begins a correctly written Arabic word
- `low` — word ends with `لا`, a pattern that rarely appears at word-end in natural Arabic

**Dictionary**:

| Found (reversed) | Suggestion (correct) | Meaning |
|------------------|----------------------|---------|
| `ثحب` | `بحث` | "search" |
| `دمحم` | `محمد` | "Muhammad" |
| `تادادعإ` | `إعدادات` | "settings" |
| `فلم` | `ملف` | "file" |
| `ظفح` | `حفظ` | "save" |

**Important**: `medium` and `low` findings mean *potentially* reversed, not definitively wrong.
Always review in context before changing.

---

## AR002 — excessive-tatweel

**Purpose**: Detect tatweel (kashida, U+0640 `ـ`) used for visual stretching. Tatweel
breaks text search and normalization.

**Severity**: `medium`

**Example**:
```
مـحـمـد
```

**Recommendation**: Remove tatweel from any text used in searchable, indexed, or stored
values. It is acceptable only in display-only artistic contexts.

---

## AR003 — tashkeel-in-search-key

**Purpose**: Detect tashkeel (diacritics, U+064B–U+065F) in text that will be used as a
search or sort key. Tashkeel causes mismatches between diacritized and bare forms.

**Severity**: `medium`

**Example**:
```
search_key: "مُحَمَّد"
```

**Recommendation**: Strip tashkeel before indexing. `toSearchKey()` from
`@devsamhan/arabic-text` removes tashkeel automatically.

---

## AR004 — mixed-digit-scripts

**Purpose**: Detect lines that contain both Eastern Arabic digits (٠١٢٣٤٥٦٧٨٩,
U+0660–U+0669) and Western Arabic digits (0–9) on the same line. Mixed scripts cause
inconsistent display and sort order.

**Severity**: `low`

**Example**:
```
رقم ١٢3
```

**Recommendation**: Normalize digit scripts intentionally. Use `normalizeDigits()` from
`@devsamhan/arabic-text` to convert Eastern to Western, or use Eastern throughout.
