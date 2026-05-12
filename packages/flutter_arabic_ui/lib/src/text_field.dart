library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arabic_text/arabic_text.dart';
import 'formatters.dart';

/// Arabic-aware [TextField] with RTL layout and optional live normalization.
///
/// Always sets [textDirection] to [TextDirection.rtl] and
/// [textAlign] to [TextAlign.right].
///
/// When [autoNormalize] is `true`, an [ArabicInputFormatter] with
/// [normalizeOptions] is prepended to the formatter chain before any
/// developer-supplied [inputFormatters].
class ArabicTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextStyle? style;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autofocus;

  /// When `true`, prepends [ArabicInputFormatter] to the formatter chain.
  /// Default: `false`.
  final bool autoNormalize;

  /// Normalization options used when [autoNormalize] is `true`.
  final ArabicNormalizeOptions normalizeOptions;

  /// Additional formatters appended after the auto-normalizer (if any).
  final List<TextInputFormatter>? inputFormatters;

  const ArabicTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.style,
    this.onChanged,
    this.enabled = true,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.autofocus = false,
    this.autoNormalize = false,
    this.normalizeOptions = const ArabicNormalizeOptions(
      removeTashkeel: true,
      removeTatweel: true,
      trimWhitespace: false,
      collapseWhitespace: false,
    ),
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFormatters = <TextInputFormatter>[
      if (autoNormalize) ArabicInputFormatter(options: normalizeOptions),
      if (inputFormatters != null) ...inputFormatters!,
    ];

    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: decoration,
      style: style,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      onChanged: onChanged,
      enabled: enabled,
      obscureText: obscureText,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofocus: autofocus,
      inputFormatters: effectiveFormatters.isEmpty ? null : effectiveFormatters,
    );
  }
}
