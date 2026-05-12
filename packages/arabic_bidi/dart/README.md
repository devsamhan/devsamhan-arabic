# arabic_bidi

Arabic terminal display helpers for Dart.

## What it does

- Reshape Arabic letters to correct contextual forms (isolated / initial / medial / final)
- Detect text direction (RTL / LTR / mixed)
- Prepare Arabic text for LTR terminal display (run-level reordering)

## What it does NOT do

- **No full Unicode Bidirectional Algorithm (UAX #9)** — paragraph-level reordering is not implemented
- **No Flutter / browser / web UI rendering** — modern platforms handle Arabic natively, no library needed there
- **No normalization** — use [arabic_text](https://pub.dev/packages/arabic_text) for tashkeel removal, alef normalization, search keys, etc.

## When to use it

Use `arabic_bidi` for: CLI tools, dart scripts, terminal logging, server-side log output, any environment where Arabic text renders as disconnected letters.

**Do NOT use `arabic_bidi` for Flutter apps, web apps, or any platform that natively supports Arabic text rendering.**

## Quick start

```dart
import 'package:arabic_bidi/arabic_bidi.dart';

// Reshape only — correct letter forms, no reordering
ArabicBidi.reshape('محمد');             // → connected presentation forms

// Full terminal preparation — reshape + best-effort run reordering
ArabicBidi.prepareForTerminal('السلام عليكم');  // → shaped + reordered for LTR

// Print directly to stdout
ArabicBidi.printArabic('مرحبا بالعالم');

// Direction detection
ArabicBidi.isRTL('مرحبا');                      // true
ArabicBidi.detectDirection('Hello مرحبا World'); // Direction.mixed
```

## Lam-Alef ligatures

Lam-alef ligature substitution (ل+ا → ﻻ) is opt-in. Disabled by default
because not all terminal fonts render Presentation Forms correctly.

```dart
// Default — no ligatures (cross-platform safe)
ArabicBidi.reshape('السلام');
// → ا_iso + ل_ini + س_med + ل_med + ا_fin + م_iso

// Opt-in ligatures
ArabicBidi.reshape('السلام',
    options: const ArabicReshapeOptions(useLamAlefLigatures: true));
// → ا_iso + ل_ini + س_med + [لا final ligature] + م_iso
```

Supported lam-alef pairs: `لا لأ لإ لآ`

## Mixed text

When Arabic and Latin text appear together, use `reorder: false` if the
Latin portion must stay anchored in place (e.g. log lines with error codes).

```dart
// Default — Arabic-dominant text gets run-level reordering
ArabicBidi.prepareForTerminal('ملف 123 محفوظ');
// → محفوظ 123 ملف  (runs reversed; "123" moves as a unit)

// reorder: false — shape only, keep original run order
ArabicBidi.prepareForTerminal(
  'Error في الملف',
  options: const ArabicTerminalOptions(reorder: false),
);
// → Error في_shaped الملف_shaped  (no run reversal)
```

Arabic-dominant = Arabic letter fraction **> 0.5** (strict majority).
Tashkeel, tatweel, and digit code points are not counted toward the ratio.

Numeric runs (ASCII `0–9`, Eastern Arabic `٠–٩`, Persian `۰–۹`) are never
reshaped and move as a unit during run reversal.

## Logger

Drop-in Arabic-aware logger for CLI apps and scripts.

```dart
import 'package:arabic_bidi/arabic_bidi.dart';

// Use default instance
arabicLogger.info('تم التشغيل بنجاح');
arabicLogger.error('خطأ في الاتصال');

// Custom prefix
final log = ArabicLogger(prefix: 'MyApp');
log.warn('تحذير: الذاكرة ممتلئة');

// With timestamp
final log = ArabicLogger(useTimestamp: true);
log.info('بدء المعالجة');
```

Output format:

```
[INFO] مرحبا
[ERROR] خطأ في الاتصال
[MyApp][WARN] تحذير
[2024-01-01 12:00:00][INFO] رسالة
```

## Known limitations

- Reordering is run-level, not paragraph-level (not UAX #9)
- Punctuation adjacent to Arabic text may render unexpectedly
- Mixed Arabic / Latin lines: use `reorder: false` if Latin must stay anchored
- Arabic signs U+0600–U+0620 are treated as punctuation-like runs (v1)
- Not a replacement for UAX #9

## Joining capability reference

| Type | joinsRight | joinsLeft | Letters |
|------|-----------|-----------|---------|
| D (dual) | ✓ | ✓ | ب ت ث ج ح خ س ش ص ض ط ظ ع غ ف ق ك ل م ن ه ي ئ ة |
| R (right) | ✗ | ✓ | ا أ إ آ د ذ ر ز و ؤ ى |
| U (none) | ✗ | ✗ | ء |
| Transparent | — | — | tashkeel (U+064B–U+065F), tatweel (U+0640) |

## Form selection rules

```
medial   = prevJoinsRight ∧ selfJoinsLeft ∧ selfJoinsRight ∧ nextJoinsLeft
final    = prevJoinsRight ∧ selfJoinsLeft ∧ ¬(selfJoinsRight ∧ nextJoinsLeft)
initial  = ¬prevJoinsRight ∧ selfJoinsRight ∧ nextJoinsLeft
isolated = otherwise
```

## Coverage

- U+0621–U+063A (ء–غ) and U+0641–U+064A (ف–ي): full contextual forms
- U+064B–U+065F tashkeel: transparent (preserved in output)
- U+0640 tatweel: transparent (preserved in output)
- U+063B–U+063F rare extended letters: pass through unchanged

## Spec

Part of the [devsamhan-arabic](https://github.com/devsamhan/devsamhan-arabic) library suite.

## License

MIT
