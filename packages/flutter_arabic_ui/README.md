# flutter_arabic_ui

Arabic-first Flutter UI components — RTL text fields, search, number input,
formatters, controllers, and validators.

Part of the [devsamhan-arabic](https://github.com/devsamhan/devsamhan-arabic) monorepo.

---

## Widgets

### ArabicTextField

RTL [TextField] with optional live normalization.

```dart
ArabicTextField(
  autoNormalize: true,   // strips tashkeel and tatweel on every keystroke
  onChanged: (text) => print(text),
)
```

### ArabicSearchField

RTL search field with live search-key derivation.

```dart
ArabicSearchField(
  onSearchKeyChanged: (key) => query(key),  // receives toSearchKey(raw)
  normalizeVisibleText: false,              // default: visible text stays raw
)
```

### ArabicNumberField

Numeric field that converts digit scripts on every keystroke.

```dart
ArabicNumberField(
  digitDirection: ArabicDigitDirection.eastern,  // 123 → ١٢٣
  onNormalizedChanged: (v) => parse(v),          // always delivers western digits
)
```

---

## Formatters

Attach directly to any [TextField.inputFormatters].

| Formatter | Effect |
|-----------|--------|
| `ArabicInputFormatter` | Removes tashkeel and tatweel (configurable) |
| `ArabicNumberFormatter` | Converts between Eastern / Western digit scripts |
| `ArabicSearchKeyFormatter` | Applies `ArabicText.toSearchKey` on every keystroke |

---

## Controllers

### ArabicTextEditingController

Drop-in replacement for [TextEditingController] with Arabic utility getters.

```dart
final c = ArabicTextEditingController();

c.text = 'مُحَمَّد';
print(c.searchKey);      // ArabicText.toSearchKey(text)
print(c.looseSearchKey); // ArabicText.toLooseSearchKey(text)
print(c.displayKey);     // ArabicText.toDisplayKey(text)
print(c.slug);           // ArabicText.toSlug(text)

// Explicit normalization only — text is NEVER auto-mutated.
// Getters derive values on every call; they do not modify stored text.
c.normalizeInPlace(
  const ArabicNormalizeOptions(removeTashkeel: true),
);
```

> **Warning:** Getters are read-only derivations. Do not auto-mutate text.
> Use `normalizeInPlace` explicitly, or attach an `ArabicInputFormatter` at
> the widget layer for live normalization.

### ArabicSearchController

```dart
final c = ArabicSearchController();
c.text = 'مُحَمَّد';
print(c.searchKey);      // normalized search key
print(c.looseSearchKey); // loose (ta-marbouta collapsed) search key
```

---

## Validators

Static validators compatible with [TextFormField.validator].

```dart
TextFormField(
  validator: ArabicValidators.requiredArabic,
)

TextFormField(
  validator: ArabicValidators.arabicOnly,
)

TextFormField(
  validator: ArabicValidators.minArabicLetters(3),
)

TextFormField(
  validator: ArabicValidators.maxArabicLetters(20),
)

TextFormField(
  // accepts Western 0-9, Eastern Arabic ٠-٩, and Persian ۰-۹
  validator: ArabicValidators.numericArabic,
)
```

> **Note:** All validators are compatible with Flutter Form / TextFormField
> validator. They return `null` on success and an Arabic error string on
> failure. Validators never normalize or mutate the input value.

| Validator | Passes when |
|-----------|-------------|
| `requiredArabic` | non-null, non-empty after trim |
| `arabicOnly` | all code points are in the Arabic Unicode block |
| `mixedArabicText` | at least one Arabic code point present |
| `minArabicLetters(n)` | Arabic letter count ≥ n |
| `maxArabicLetters(n)` | Arabic letter count ≤ n |
| `numericArabic` | parses as a number; accepts Western (0–9), Eastern Arabic (٠–٩), and Persian (۰–۹) digits |
