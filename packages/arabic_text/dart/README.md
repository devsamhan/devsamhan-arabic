# arabic_text

Arabic text normalization for Dart and Flutter.
Zero runtime dependencies. Conformant with [devsamhan-arabic spec v1.0.0](https://github.com/devsamhan/devsamhan-arabic).

## What this package does

- Removes tashkeel (short vowels, shadda, tanwin, sukun) and tatweel (kashida)
- Normalizes Alef variants (أ إ آ ٱ → ا), hamza seats (ؤ ئ → ء), and Ya variants (ى ی → ي)
- Converts Arabic Presentation Forms (FB50–FDFF, FE70–FEFF) to canonical Unicode
- Generates search keys for database indexing and full-text search
- Generates stable lexical sort keys for sorting Arabic strings
- Normalizes names for deduplication and matching
- Produces URL-safe Unicode Arabic slugs

## What this package does NOT do

- **No bidirectional (bidi) text reordering** — use the ICU bidi algorithm for display
- **No terminal / visual reshaping** — Arabic letters are stored in logical order
- **No spelling correction** — hamza placement is normalized for search, not corrected
- **No full Arabic dictionary collation** — `sort()` is normalized Unicode lexical order, not Arabic alphabet order; a future `ArabicCollator` will handle that

## Philosophy

Conservative by default: no normalization happens unless explicitly requested — under-normalized is recoverable, over-normalized may corrupt names or legal text.

## Installation

```yaml
dependencies:
  arabic_text: ^1.0.0
```

## Quick start

```dart
import 'package:arabic_text/arabic_text.dart';

// Remove tashkeel, normalize alef/hamza/ya — ready for database indexing
ArabicText.toSearchKey('مُحَمَّدٌ');           // → 'محمد'
ArabicText.toSearchKey('أَبُو ظَبْيٍ');       // → 'ابو ظبي'

// Remove tatweel only, keep tashkeel — safe for display
ArabicText.toDisplayKey('مـحـمـد');           // → 'محمد'

// URL-safe Unicode slug
ArabicText.toSlug('مدينة الرياض');            // → 'مدينه-الرياض'

// Name deduplication — keeps ى and ة; normalizes Persian ی → ي
ArabicText.normalizeName('فَاطِمَةُ');         // → 'فاطمة'
```

## toSearchKey vs toLooseSearchKey

`toSearchKey` preserves ة. `toLooseSearchKey` converts ة → ه.

```dart
ArabicText.toSearchKey('فَاطِمَةُ');      // → 'فاطمة'
ArabicText.toLooseSearchKey('فَاطِمَةُ'); // → 'فاطمه'
```

Use `toLooseSearchKey` only for normalizing the incoming search query — never
for storage. This lets فاطمة and فاطمه match the same records regardless of
how the user typed the name.

## Database pattern

```dart
// Store — preserves ة in the indexed key
user.searchKey = ArabicText.toSearchKey(user.name);

// Search — converts ة → ه on both sides so variants match
db.where('search_key = ?', [ArabicText.toLooseSearchKey(query)]);
```

## Sorting

```dart
ArabicText.sort(['يوسف', 'أحمد', 'إبراهيم', 'محمد', 'آدم']);
// → ['إبراهيم', 'أحمد', 'آدم', 'محمد', 'يوسف']
```

**Warning:** `sort()` produces normalized Unicode lexical order, not Arabic
dictionary order. The definite article (ال) is not stripped, and ة / ه sort
separately. Do not advertise this as "Arabic alphabetical order."

## Spec version

```dart
print(ArabicText.specVersion); // '1.0.0'
assert(ArabicText.specVersion == '1.0.0', 'unexpected spec version');
```

## API reference

### ArabicText class (recommended)

| Method | Description |
|---|---|
| `toSearchKey(text)` | Normalized key for storage/indexing. Preserves ة. |
| `toLooseSearchKey(text)` | Like toSearchKey + ة→ه. Query side only. |
| `toDisplayKey(text)` | Removes tatweel only. Preserves tashkeel and hamza. |
| `toSlug(text)` | URL-safe Unicode slug. |
| `normalizeName(text)` | Name deduplication. Keeps ى and ة. |
| `toSortKey(text)` | Normalized lexical sort key. Not locale-aware collation. |
| `sort(list)` | Stable lexical sort over toSortKey. |
| `compare(a, b)` | Returns -1, 0, or 1 by sort key. |
| `normalizePresentationForms(text)` | FB50–FDFF, FE70–FEFF → canonical. |
| `removeTashkeel(text)` | Remove all diacritics. |
| `removeTatweel(text)` | Remove U+0640. Preserves Quranic ـٰ. |
| `normalizeAlef(text)` | أ إ آ ٱ → ا |
| `normalizeHamza(text)` | ؤ ئ → ء |
| `normalizeYa(text)` | ى ی → ي |
| `normalizeTaMarbouta(text)` | ة → ه. Explicit-only. |
| `normalizeDigits(text, to:)` | `'western'` or `'eastern'`. |
| `isArabic(text)` | true if any Arabic code point present. |
| `arabicRatio(text)` | Fraction of Arabic code points (0.0–1.0). |
| `specVersion` | `'1.0.0'` |

### ArabicNormalizeOptions

For precise control over which normalizations apply:

```dart
normalize(text, ArabicNormalizeOptions(
  removeTashkeel: true,
  normalizeAlef: true,
  normalizeTaMarbouta: true,   // must be explicit
  normalizeDigits: 'western',
));
```

All flags default to `false` (most conservative). `normalizePresentationForms`
defaults to `true`.

## Spec

Full behavioral specification: [`SPEC.md`](https://github.com/devsamhan/devsamhan-arabic/blob/main/claude/SPEC.md)

## License

MIT
