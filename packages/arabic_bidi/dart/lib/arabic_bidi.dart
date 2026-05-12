/// Arabic terminal display helpers — devsamhan-arabic arabic_bidi v1.0.0.
///
/// Primary entry point: [ArabicBidi] static class.
///
/// ## Scope
/// Terminal display helpers only. This is NOT a full Unicode BiDi engine.
/// For Flutter, browsers, and modern UI, Arabic renders natively — no library
/// needed. Use this package for CLI tools, terminal scripts, and server logs.
library arabic_bidi;

export 'src/reshaper.dart' show ArabicReshapeOptions;
export 'src/terminal.dart' show ArabicTerminalOptions;
export 'src/logger.dart' show ArabicLogger, arabicLogger;

import 'src/reshaper.dart' as _r;
import 'src/bidi.dart' as _b;
import 'src/terminal.dart' as _t;

/// Spec version of this library.
const String specVersion = '1.0.0';

/// Text direction classification.
enum Direction { rtl, ltr, mixed }

/// Static facade over all arabic_bidi functions.
abstract final class ArabicBidi {
  /// Applies Arabic contextual shaping — connects letters using their correct
  /// initial/medial/final/isolated Unicode forms.
  /// Does not reorder text. Safe for all environments.
  ///
  /// Input: logical-order Arabic (U+0621–U+064A).
  /// Output: Presentation Forms-B (U+FE70–U+FEFF).
  /// Non-Arabic characters and tashkeel marks pass through unchanged.
  ///
  /// Pass [options] to enable lam-alef ligature substitution.
  static String reshape(String text,
          {_r.ArabicReshapeOptions options =
              _r.ArabicReshapeOptions.defaults}) =>
      _r.reshape(text, options: options);

  /// Return [text] in visual order suitable for an LTR terminal.
  ///
  /// Not yet implemented — returns [text] unchanged.
  static String getVisualOrder(String text) => _b.getVisualOrder(text);

  /// Combined reshape + visual order — legacy single-argument API.
  ///
  /// Prefer [prepareForTerminal] for new code.
  static String forTerminal(String text,
          {_r.ArabicReshapeOptions options =
              _r.ArabicReshapeOptions.defaults}) =>
      getVisualOrder(reshape(text, options: options));

  /// Best-effort preparation for LTR terminal display.
  /// Reshapes Arabic runs and optionally reverses run order.
  /// This is NOT a full Unicode Bidirectional Algorithm (UAX #9).
  /// For Flutter, browsers, and modern UI — do not use this.
  /// For CLI, logs, and terminal scripts — this is the right tool.
  static String prepareForTerminal(String text,
          {_t.ArabicTerminalOptions? options}) =>
      _t.prepareForTerminal(text, options: options);

  /// Print [text] prepared for terminal display to stdout.
  static void printArabic(String text, {_t.ArabicTerminalOptions? options}) =>
      print(prepareForTerminal(text, options: options));

  /// Return `true` if [text] contains more RTL characters than LTR.
  static bool isRTL(String text) => detectDirection(text) == Direction.rtl;

  /// Returns the dominant direction of [text] based on Arabic letter ratio.
  /// Returns [Direction.mixed] if ratio is exactly 0.5.
  ///
  /// Counts Arabic-block code points (U+0600–U+06FF) vs Basic Latin letters
  /// (A–Z, a–z). Returns [Direction.mixed] when neither is dominant (< 80%).
  static Direction detectDirection(String text) {
    if (text.isEmpty) return Direction.ltr;
    int arabic = 0, latin = 0;
    for (final r in text.runes) {
      if (r >= 0x0600 && r <= 0x06FF) arabic++;
      if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A)) latin++;
    }
    final total = arabic + latin;
    if (total == 0) return Direction.ltr;
    if (arabic / total >= 0.8) return Direction.rtl;
    if (latin / total >= 0.8) return Direction.ltr;
    return Direction.mixed;
  }

  /// Wrap [text] at word boundaries so no line exceeds [width] characters.
  ///
  /// Splits on spaces; does not hyphenate.
  static String wrapForTerminal(String text, {required int width}) {
    if (text.length <= width) return text;
    final words = text.split(' ');
    final lines = <String>[];
    final current = StringBuffer();
    for (final word in words) {
      if (current.isEmpty) {
        current.write(word);
      } else if (current.length + 1 + word.length <= width) {
        current.write(' $word');
      } else {
        lines.add(current.toString());
        current.clear();
        current.write(word);
      }
    }
    if (current.isNotEmpty) lines.add(current.toString());
    return lines.join('\n');
  }
}
