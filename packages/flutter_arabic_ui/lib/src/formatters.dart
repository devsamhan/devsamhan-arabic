library;

import 'package:flutter/services.dart';
import 'package:arabic_text/arabic_text.dart';

// Default options for ArabicInputFormatter.
// trimWhitespace and collapseWhitespace are disabled so that typing spaces
// mid-sentence is not disrupted on every keystroke.
const _kInputDefaults = ArabicNormalizeOptions(
  removeTashkeel: true,
  removeTatweel: true,
  trimWhitespace: false,
  collapseWhitespace: false,
);

/// Applies [ArabicText.normalize] to every keystroke.
///
/// Default options remove tashkeel and tatweel; all other normalisations
/// are opt-in via a custom [ArabicNormalizeOptions].
/// Cursor position is adjusted proportionally when characters are removed.
class ArabicInputFormatter implements TextInputFormatter {
  final ArabicNormalizeOptions options;

  const ArabicInputFormatter({this.options = _kInputDefaults});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      _apply(newValue, (s) => ArabicText.normalize(s, options));
}

/// Digit script direction for [ArabicNumberFormatter] and [ArabicNumberField].
enum ArabicDigitDirection {
  /// Convert Eastern/Persian digits to Western `0–9`.
  western,

  /// Convert Western `0–9` to Eastern Arabic `٠–٩`.
  eastern,
}

/// Converts digit scripts on every keystroke.
class ArabicNumberFormatter implements TextInputFormatter {
  final ArabicDigitDirection direction;

  const ArabicNumberFormatter({required this.direction});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      _apply(
          newValue, (s) => ArabicText.normalizeDigits(s, to: direction.name));
}

/// Silently applies [ArabicText.toSearchKey] on every keystroke.
///
/// Used internally by ArabicSearchField. Prefer [ArabicInputFormatter] for
/// user-visible text fields where whitespace collapsing would be disruptive.
class ArabicSearchKeyFormatter implements TextInputFormatter {
  const ArabicSearchKeyFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      _apply(newValue, ArabicText.toSearchKey);
}

// ── Cursor-aware transform helper ─────────────────────────────────────────────

// Applies [transform] to [value.text] and adjusts the selection by applying
// the same transform to the text before each selection boundary.
TextEditingValue _apply(
  TextEditingValue value,
  String Function(String) transform,
) {
  final original = value.text;
  final transformed = transform(original);
  if (transformed == original) return value;

  final end = value.selection.extentOffset.clamp(0, original.length);
  final start = value.selection.baseOffset.clamp(0, original.length);

  final newEnd = transform(original.substring(0, end)).length;
  final newStart =
      start == end ? newEnd : transform(original.substring(0, start)).length;

  return value.copyWith(
    text: transformed,
    selection: TextSelection(
      baseOffset: newStart.clamp(0, transformed.length),
      extentOffset: newEnd.clamp(0, transformed.length),
    ),
  );
}
