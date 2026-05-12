## 1.0.0

- Initial Dart release.
- 7 surgical normalization functions: `normalizePresentationForms`,
  `removeTashkeel`, `removeTatweel`, `normalizeAlef`, `normalizeHamza`,
  `normalizeYa`, `normalizeTaMarbouta`, `normalizeDigits`.
- 6 presets: `toSearchKey`, `toLooseSearchKey`, `toDisplayKey`,
  `toSlug`, `normalizeName`, `toSortKey`.
- Utility functions: `sort`, `compare`, `isArabic`, `arabicRatio`.
- `ArabicNormalizeOptions` for fine-grained control.
- `ArabicText` static class facade over all top-level functions.
- Shared SPEC v1.0.0 fixture compatibility — identical behavior across
  all devsamhan-arabic language implementations.
- Zero dependencies.
