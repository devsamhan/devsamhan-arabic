## 1.1.0

- Package release coordinated with npm and PyPI `1.1.0`.
- SPEC_VERSION clarified to `1.0.1`; no public API shape change.
- Documents Persian (U+06F0-U+06F9) to Eastern Arabic (U+0660-U+0669)
  conversion in `normalizeDigits`; conversion remains explicit-only.
- Documents strict versus loose search keys and original-text preservation.
- Clients that persisted `normalizeDigits(text, 'eastern')` output may need a
  one-time reindex/backfill; see the release notes.

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
