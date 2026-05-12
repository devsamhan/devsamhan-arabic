library;

import 'reshaper.dart' as _r;

// ── Run types ─────────────────────────────────────────────────────────────────

enum _RunType { arabic, latin, number, space, punctuation }

_RunType _classify(int cp) {
  // Arabic letters U+0621–U+063A and U+0641–U+064A, tatweel U+0640,
  // tashkeel U+064B–U+065F — the full range 0x0621–0x065F.
  if (cp >= 0x0621 && cp <= 0x065F) return _RunType.arabic;
  if ((cp >= 0x41 && cp <= 0x5A) || (cp >= 0x61 && cp <= 0x7A))
    return _RunType.latin;
  // ASCII 0–9, Eastern Arabic U+0660–U+0669, Persian U+06F0–U+06F9.
  if ((cp >= 0x30 && cp <= 0x39) ||
      (cp >= 0x0660 && cp <= 0x0669) ||
      (cp >= 0x06F0 && cp <= 0x06F9)) return _RunType.number;
  if (cp == 0x20 || cp == 0x09 || cp == 0x0A || cp == 0x0D)
    return _RunType.space;
  return _RunType.punctuation;
}

class _Run {
  final _RunType type;
  final String text;
  const _Run(this.type, this.text);
}

List<_Run> _splitRuns(String text) {
  if (text.isEmpty) return const [];
  final runes = text.runes.toList();
  final runs = <_Run>[];
  var currentType = _classify(runes[0]);
  var start = 0;
  for (var i = 1; i < runes.length; i++) {
    final type = _classify(runes[i]);
    if (type != currentType) {
      runs.add(
          _Run(currentType, String.fromCharCodes(runes.sublist(start, i))));
      start = i;
      currentType = type;
    }
  }
  runs.add(_Run(currentType, String.fromCharCodes(runes.sublist(start))));
  return runs;
}

// ── Arabic letter ratio ───────────────────────────────────────────────────────

// Fraction of scalar values in [text] that are Arabic letters
// (U+0621–U+063A, U+0641–U+064A). Tashkeel, tatweel, and digit code points
// are excluded so that "رقم ١٢٣" does not inflate the ratio beyond the true
// letter majority.
double _arabicLetterRatio(String text) {
  if (text.isEmpty) return 0.0;
  var letters = 0;
  var total = 0;
  for (final r in text.runes) {
    total++;
    if ((r >= 0x0621 && r <= 0x063A) || (r >= 0x0641 && r <= 0x064A)) {
      letters++;
    }
  }
  return total == 0 ? 0.0 : letters / total;
}

// ── Options ───────────────────────────────────────────────────────────────────

/// Options controlling [prepareForTerminal] behaviour.
///
/// ```dart
/// // Defaults: reshape + reorder, no ligatures
/// prepareForTerminal(text);
///
/// // Reshape only — useful when the calling code handles run ordering itself
/// prepareForTerminal(text, options: const ArabicTerminalOptions.reshapeOnly());
/// ```
class ArabicTerminalOptions {
  /// Apply contextual reshaping to Arabic letter runs. Default: `true`.
  final bool reshape;

  /// When true, reverses run order for LTR terminal display.
  /// Auto-applies only when Arabic letter ratio > 0.5.
  /// Set to false for mixed text where Latin must stay anchored.
  final bool reorder;

  /// Collapse ل+alef pairs into lam-alef ligatures. Default: `false`.
  ///
  /// Passed through to [ArabicReshapeOptions.useLamAlefLigatures].
  final bool useLamAlefLigatures;

  const ArabicTerminalOptions({
    this.reshape = true,
    this.reorder = true,
    this.useLamAlefLigatures = false,
  });

  /// Reshape only — no run reordering, no ligatures.
  const ArabicTerminalOptions.reshapeOnly()
      : reshape = true,
        reorder = false,
        useLamAlefLigatures = false;
}

// ── Public API ────────────────────────────────────────────────────────────────

/// Prepare [text] for display on an LTR terminal.
///
/// Splits text into typed runs (Arabic, Latin, number, space, punctuation),
/// reshapes Arabic runs, and — when the text is Arabic-dominant — reverses
/// run order for correct LTR display. Latin, number, and punctuation runs
/// are never character-reversed.
///
/// ## Arabic-dominant threshold
/// Arabic letter fraction (U+0621–U+063A, U+0641–U+064A) must be **> 0.5**
/// (strict majority of all code points). Tashkeel, tatweel, and digit code
/// points are not counted, so "رقم ١٢٣" (3 letters / 7 total = 0.43) is
/// not treated as Arabic-dominant.
///
/// ## Numeric runs
/// ASCII digits (0–9), Eastern Arabic (U+0660–U+0669), and Persian
/// (U+06F0–U+06F9) digits are classified as NumberRun and are never reshaped.
/// During run reversal they move as a unit; their character order is preserved.
///
/// ## Limitations
/// This is best-effort reordering. It is NOT a full Unicode Bidirectional
/// Algorithm (UAX #9) implementation. Mixed text (Arabic + Latin) reordering
/// is run-level only. Use `reorder: false` for predictable Latin preservation.
String prepareForTerminal(String text, {ArabicTerminalOptions? options}) {
  if (text.isEmpty) return text;
  final opts = options ?? const ArabicTerminalOptions();
  final runs = _splitRuns(text);

  // Reshape Arabic runs.
  final reshaped = opts.reshape
      ? runs.map((run) {
          if (run.type != _RunType.arabic) return run;
          return _Run(
            _RunType.arabic,
            _r.reshape(
              run.text,
              options: _r.ArabicReshapeOptions(
                  useLamAlefLigatures: opts.useLamAlefLigatures),
            ),
          );
        }).toList()
      : runs;

  // Reverse run order for Arabic-dominant text.
  final ordered = opts.reorder && _arabicLetterRatio(text) > 0.5
      ? reshaped.reversed.toList()
      : reshaped;

  return ordered.map((r) => r.text).join();
}

/// Print [text] prepared for terminal display to stdout.
void printArabic(String text, {ArabicTerminalOptions? options}) =>
    print(prepareForTerminal(text, options: options));
