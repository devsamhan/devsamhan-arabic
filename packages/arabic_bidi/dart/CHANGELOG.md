## 1.0.0

- Initial Dart release.
- Arabic contextual reshaping: isolated / initial / medial / final forms
  for all standard Arabic letters (U+0621–U+064A).
- Optional lam-alef ligature substitution (opt-in via `ArabicReshapeOptions`).
- Direction detection: RTL / LTR / mixed based on Arabic letter ratio.
- Best-effort terminal preparation (`prepareForTerminal`) with run-level
  reordering for LTR terminal display.
- Arabic letter ratio > 0.5 threshold for auto-reorder.
- Eastern Arabic (U+0660–U+0669) and Persian (U+06F0–U+06F9) digits treated
  as numeric runs — never reshaped.
- Zero dependencies beyond `arabic_text`.
- ArabicLogger: Arabic-aware drop-in terminal logger.
