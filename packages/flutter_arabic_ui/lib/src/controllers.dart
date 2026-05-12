library;

import 'package:flutter/widgets.dart';
import 'package:arabic_text/arabic_text.dart';

/// [TextEditingController] enriched with Arabic text utility getters
/// and an explicit in-place normalization helper.
///
/// Getters derive their values on every call from the current [text].
/// Text is NEVER mutated automatically — call [normalizeInPlace] explicitly.
class ArabicTextEditingController extends TextEditingController {
  ArabicTextEditingController({super.text});

  String get searchKey => ArabicText.toSearchKey(text);
  String get looseSearchKey => ArabicText.toLooseSearchKey(text);
  String get displayKey => ArabicText.toDisplayKey(text);
  String get slug => ArabicText.toSlug(text);

  /// Replace [value.text] with its normalized form and adjust the cursor.
  ///
  /// When [options] is omitted the default [ArabicNormalizeOptions] is used
  /// (only presentation-form normalization and whitespace trimming are active
  /// by default).
  void normalizeInPlace([ArabicNormalizeOptions? options]) {
    value = value.copyWith(
      text: ArabicText.normalize(
        text,
        options ?? const ArabicNormalizeOptions(),
      ),
    );
  }
}

/// [TextEditingController] for Arabic search inputs.
///
/// Provides [searchKey] and [looseSearchKey] derived from the current text.
/// Visible text is NEVER mutated automatically — apply formatters at the
/// widget layer if live normalisation of the visible text is needed.
class ArabicSearchController extends TextEditingController {
  ArabicSearchController({super.text});

  String get searchKey => ArabicText.toSearchKey(text);
  String get looseSearchKey => ArabicText.toLooseSearchKey(text);
}
