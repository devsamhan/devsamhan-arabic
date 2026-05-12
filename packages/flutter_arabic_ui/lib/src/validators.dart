library;

import 'package:flutter/widgets.dart';
import 'package:arabic_text/arabic_text.dart';

/// Static Arabic-aware validators compatible with [FormFieldValidator].
///
/// Pass any method directly to a [TextFormField.validator] parameter.
/// All validators return `null` on success and an Arabic error string on
/// failure.
abstract final class ArabicValidators {
  static String? requiredArabic(String? value) {
    if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
    return null;
  }

  static FormFieldValidator<String> minArabicLetters(int min) =>
      (String? value) {
        final count = (value ?? '')
            .runes
            .where(
              (r) =>
                  (r >= 0x0621 && r <= 0x063A) || (r >= 0x0641 && r <= 0x064A),
            )
            .length;
        return count >= min ? null : 'عدد الأحرف العربية أقل من المطلوب';
      };

  static FormFieldValidator<String> maxArabicLetters(int max) =>
      (String? value) {
        final count = (value ?? '')
            .runes
            .where(
              (r) =>
                  (r >= 0x0621 && r <= 0x063A) || (r >= 0x0641 && r <= 0x064A),
            )
            .length;
        return count <= max ? null : 'عدد الأحرف العربية أكبر من المسموح';
      };

  static String? arabicOnly(String? value) {
    if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
    if (ArabicText.arabicRatio(value) < 1.0) return 'يجب إدخال نص عربي فقط';
    return null;
  }

  static String? mixedArabicText(String? value) {
    if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
    if (ArabicText.arabicRatio(value) == 0.0)
      return 'يجب أن يحتوي النص على أحرف عربية';
    return null;
  }

  /// Returns `null` when [value] represents a valid number in any of:
  /// Western digits (0–9), Eastern Arabic digits (٠–٩, U+0660–U+0669),
  /// or Persian digits (۰–۹, U+06F0–U+06F9).
  ///
  /// The input value is never mutated. Digit normalization is applied only
  /// internally to perform the numeric parse check.
  static String? numericArabic(String? value) {
    if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
    final normalized = ArabicText.normalizeDigits(value, to: 'western');
    if (double.tryParse(normalized) == null) return 'يجب إدخال رقم صحيح';
    return null;
  }
}
