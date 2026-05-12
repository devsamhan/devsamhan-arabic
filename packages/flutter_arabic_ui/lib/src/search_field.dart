library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arabic_text/arabic_text.dart';
import 'formatters.dart';

/// Arabic-aware search field with RTL layout and live search-key derivation.
///
/// [onChanged] receives the raw text as the user types.
/// [onSearchKeyChanged] receives [ArabicText.toSearchKey] of the raw text,
/// suitable for querying a normalised index.
///
/// Set [normalizeVisibleText] to `true` to also apply [ArabicSearchKeyFormatter]
/// so what the user sees is the search-normalised form.
class ArabicSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// When null, defaults to `InputDecoration(hintText: 'بحث')`.
  final InputDecoration? decoration;

  /// Called with the raw (un-normalised) text on every change.
  final ValueChanged<String>? onChanged;

  /// Called with [ArabicText.toSearchKey] applied to the raw text on every change.
  final ValueChanged<String>? onSearchKeyChanged;

  final bool enabled;
  final bool autofocus;

  /// When `true`, [ArabicSearchKeyFormatter] normalises the visible text.
  /// Default: `false`.
  final bool normalizeVisibleText;

  const ArabicSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.onChanged,
    this.onSearchKeyChanged,
    this.enabled = true,
    this.autofocus = false,
    this.normalizeVisibleText = false,
  });

  @override
  State<ArabicSearchField> createState() => _ArabicSearchFieldState();
}

class _ArabicSearchFieldState extends State<ArabicSearchField> {
  late TextEditingController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _ownsController = widget.controller == null;
  }

  @override
  void didUpdateWidget(ArabicSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_ownsController) _controller.dispose();
      _controller = widget.controller ?? TextEditingController();
      _ownsController = widget.controller == null;
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    widget.onChanged?.call(value);
    widget.onSearchKeyChanged?.call(ArabicText.toSearchKey(value));
  }

  @override
  Widget build(BuildContext context) {
    final formatters = <TextInputFormatter>[
      if (widget.normalizeVisibleText) const ArabicSearchKeyFormatter(),
    ];

    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      decoration: widget.decoration ?? const InputDecoration(hintText: 'بحث'),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      onChanged: _handleChanged,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      inputFormatters: formatters.isEmpty ? null : formatters,
    );
  }
}
