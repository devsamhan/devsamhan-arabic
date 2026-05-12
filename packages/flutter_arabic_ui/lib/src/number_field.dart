library;

import 'package:flutter/material.dart';
import 'package:arabic_text/arabic_text.dart';
import 'formatters.dart';

/// Arabic-aware numeric field that converts digit scripts on every keystroke.
///
/// Attaches [ArabicNumberFormatter] automatically.
/// [onNormalizedChanged] always delivers Western digits regardless of
/// [digitDirection], making it safe to pass directly to numeric parsers.
///
/// Defaults to [TextDirection.ltr] and [TextAlign.left] — numeric input is
/// typically LTR even in Arabic-language apps. Override via [textDirection]
/// and [textAlign] when embedding in an RTL form.
class ArabicNumberField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;

  /// Digit conversion direction. Default: [ArabicDigitDirection.western].
  final ArabicDigitDirection digitDirection;

  /// Called with the text as it appears in the field (post-formatter).
  final ValueChanged<String>? onChanged;

  /// Called with Western digits regardless of [digitDirection].
  final ValueChanged<String>? onNormalizedChanged;

  final bool enabled;

  /// Default: [TextInputType.number].
  final TextInputType keyboardType;

  /// Text direction. Default: [TextDirection.ltr].
  final TextDirection? textDirection;

  /// Text alignment. Default: [TextAlign.left].
  final TextAlign? textAlign;

  const ArabicNumberField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.digitDirection = ArabicDigitDirection.western,
    this.onChanged,
    this.onNormalizedChanged,
    this.enabled = true,
    this.keyboardType = TextInputType.number,
    this.textDirection,
    this.textAlign,
  });

  void _handleChanged(String value) {
    onChanged?.call(value);
    onNormalizedChanged?.call(
      ArabicText.normalizeDigits(value, to: 'western'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: decoration,
      textDirection: textDirection ?? TextDirection.ltr,
      textAlign: textAlign ?? TextAlign.left,
      keyboardType: keyboardType,
      enabled: enabled,
      inputFormatters: [ArabicNumberFormatter(direction: digitDirection)],
      onChanged: _handleChanged,
    );
  }
}
