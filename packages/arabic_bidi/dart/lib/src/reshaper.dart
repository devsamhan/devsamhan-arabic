library;

/// Arabic letter reshaper.
///
/// Converts logical-order Arabic letters (canonical Unicode U+0621–U+064A) to
/// their contextual presentation forms (U+FE70–U+FEFF) based on each letter's
/// joining context (isolated / final / initial / medial).
///
/// ## Coverage
/// - U+0621–U+063A  ء … غ  (standard Arabic letters; skips rare U+063B–U+063F)
/// - U+0641–U+064A  ف … ي
/// - U+064B–U+065F  tashkeel — transparent (preserved in output, ignored for
///   joining decisions)
/// - U+0640  tatweel — transparent (same treatment as tashkeel)
///
/// ## Joining capability classification
///
/// Each letter has two independent joining axes:
/// - `joinsRight` — can extend a connection to the NEXT letter (D-type only)
/// - `joinsLeft`  — can accept a connection from the PREVIOUS letter (D or R)
///
/// | Type       | joinsRight | joinsLeft | Letters |
/// |------------|-----------|-----------|---------|
/// | D (dual)   | true       | true      | ب ت ث … ئ ة |
/// | R (right)  | false      | true      | ا أ إ آ د ذ ر ز و ؤ ى |
/// | U (none)   | false      | false     | ء |
///
/// Note: ة is classified D-type here for reshaping purposes. It has no
/// initial/medial forms in Presentation Forms-B; if those positions are
/// reached (unusual in real Arabic text), the canonical character is emitted
/// unchanged.
///
/// ## Form selection rules
/// ```
/// medial   = prevJoinsRight ∧ selfJoinsLeft ∧ selfJoinsRight ∧ nextJoinsLeft
/// final    = prevJoinsRight ∧ selfJoinsLeft ∧ ¬(selfJoinsRight ∧ nextJoinsLeft)
/// initial  = ¬prevJoinsRight ∧ selfJoinsRight ∧ nextJoinsLeft
/// isolated = otherwise
/// ```
///
/// ## Lam-alef ligatures (opt-in)
///
/// Lam-alef ligature substitution (ل+ا → ﻻ) is disabled by default.
/// Enable via [ArabicReshapeOptions.useLamAlefLigatures].
/// See [ArabicReshapeOptions] for details.
///
/// ## Limitations (v1)
/// - Not a full Unicode BiDi (UAX #9) engine.
/// - Rare extended letters U+063B–U+063F pass through unchanged.
/// - No automatic Lam-alef ligature unless opt-in.

// ── Form indices ──────────────────────────────────────────────────────────────

const int _iso = 0;
const int _fin = 1;
const int _ini = 2;
const int _med = 3;

// ── Letter → presentation form map ───────────────────────────────────────────
//
// _forms[codepoint] = [isolated, final, initial, medial]
// 0 = no form for that position (R-type letters have 0 for ini and med).

const Map<int, List<int>> _forms = {
  0x0621: [0xFE80, 0, 0, 0], //    ء  HAMZA          — U-type
  0x0622: [0xFE81, 0xFE82, 0, 0], // آ  ALEF MADDA     — R-type
  0x0623: [0xFE83, 0xFE84, 0, 0], // أ  ALEF HMZ ABOVE — R-type
  0x0624: [0xFE85, 0xFE86, 0, 0], // ؤ  WAW HMZ        — R-type
  0x0625: [0xFE87, 0xFE88, 0, 0], // إ  ALEF HMZ BELOW — R-type
  0x0626: [0xFE89, 0xFE8A, 0xFE8B, 0xFE8C], // ئ  YEH HMZ  — D-type
  0x0627: [0xFE8D, 0xFE8E, 0, 0], //    ا  ALEF          — R-type
  0x0628: [0xFE8F, 0xFE90, 0xFE91, 0xFE92], // ب  BA       — D-type
  0x0629: [
    0xFE93,
    0xFE94,
    0,
    0
  ], //    ة  TA MARBUTA    — D-type (no ini/med forms)
  0x062A: [0xFE95, 0xFE96, 0xFE97, 0xFE98], // ت  TA       — D-type
  0x062B: [0xFE99, 0xFE9A, 0xFE9B, 0xFE9C], // ث  THA      — D-type
  0x062C: [0xFE9D, 0xFE9E, 0xFE9F, 0xFEA0], // ج  JEEM     — D-type
  0x062D: [0xFEA1, 0xFEA2, 0xFEA3, 0xFEA4], // ح  HAH      — D-type
  0x062E: [0xFEA5, 0xFEA6, 0xFEA7, 0xFEA8], // خ  KHAH     — D-type
  0x062F: [0xFEA9, 0xFEAA, 0, 0], //    د  DAL            — R-type
  0x0630: [0xFEAB, 0xFEAC, 0, 0], //    ذ  THAL           — R-type
  0x0631: [0xFEAD, 0xFEAE, 0, 0], //    ر  RA             — R-type
  0x0632: [0xFEAF, 0xFEB0, 0, 0], //    ز  ZAIN           — R-type
  0x0633: [0xFEB1, 0xFEB2, 0xFEB3, 0xFEB4], // س  SEEN     — D-type
  0x0634: [0xFEB5, 0xFEB6, 0xFEB7, 0xFEB8], // ش  SHEEN    — D-type
  0x0635: [0xFEB9, 0xFEBA, 0xFEBB, 0xFEBC], // ص  SAD      — D-type
  0x0636: [0xFEBD, 0xFEBE, 0xFEBF, 0xFEC0], // ض  DAD      — D-type
  0x0637: [0xFEC1, 0xFEC2, 0xFEC3, 0xFEC4], // ط  TAH      — D-type
  0x0638: [0xFEC5, 0xFEC6, 0xFEC7, 0xFEC8], // ظ  ZAH      — D-type
  0x0639: [0xFEC9, 0xFECA, 0xFECB, 0xFECC], // ع  AIN      — D-type
  0x063A: [0xFECD, 0xFECE, 0xFECF, 0xFED0], // غ  GHAIN    — D-type
  // U+063B–U+063F: rare/extended — no Presentation Forms-B entries; pass through
  // U+0640: tatweel — transparent; not in _forms
  0x0641: [0xFED1, 0xFED2, 0xFED3, 0xFED4], // ف  FA       — D-type
  0x0642: [0xFED5, 0xFED6, 0xFED7, 0xFED8], // ق  QAF      — D-type
  0x0643: [0xFED9, 0xFEDA, 0xFEDB, 0xFEDC], // ك  KAF      — D-type
  0x0644: [0xFEDD, 0xFEDE, 0xFEDF, 0xFEE0], // ل  LAM      — D-type
  0x0645: [0xFEE1, 0xFEE2, 0xFEE3, 0xFEE4], // م  MEEM     — D-type
  0x0646: [0xFEE5, 0xFEE6, 0xFEE7, 0xFEE8], // ن  NOON     — D-type
  0x0647: [0xFEE9, 0xFEEA, 0xFEEB, 0xFEEC], // ه  HEH      — D-type
  0x0648: [0xFEED, 0xFEEE, 0, 0], //    و  WAW            — R-type
  0x0649: [0xFEEF, 0xFEF0, 0, 0], //    ى  ALEF MAQSURA   — R-type
  0x064A: [0xFEF1, 0xFEF2, 0xFEF3, 0xFEF4], // ي  YEH     — D-type
};

// ── Joining capability ────────────────────────────────────────────────────────

// R-type (right-joining only): accept connection from prev, cannot extend to next.
const _rightJoining = {
  0x0622, // آ
  0x0623, // أ
  0x0624, // ؤ
  0x0625, // إ
  0x0627, // ا
  0x062F, // د
  0x0630, // ذ
  0x0631, // ر
  0x0632, // ز
  0x0648, // و
  0x0649, // ى
};

bool _isArabicLetter(int cp) =>
    (cp >= 0x0621 && cp <= 0x063A) || (cp >= 0x0641 && cp <= 0x064A);

bool _isTransparent(int cp) => cp == 0x0640 || (cp >= 0x064B && cp <= 0x065F);

/// D-type: extends a connection to the NEXT letter (joins on the left side
/// visually, to what follows in logical order).
bool _joinsRight(int cp) =>
    _isArabicLetter(cp) && cp != 0x0621 && !_rightJoining.contains(cp);

/// D-type or R-type: accepts a connection from the PREVIOUS letter (joins on
/// the right side visually, to what precedes in logical order).
/// All Arabic letters except ء (U-type).
bool _joinsLeft(int cp) => _isArabicLetter(cp) && cp != 0x0621;

// ── Context scanning ──────────────────────────────────────────────────────────

// Return the codepoint of the nearest Arabic letter before [i], skipping
// transparent characters. Returns null if no Arabic letter is found before
// a non-transparent, non-Arabic character (or the start of string).
int? _prevArabic(List<int> runes, int i) {
  for (int j = i - 1; j >= 0; j--) {
    if (_isTransparent(runes[j])) continue;
    return _isArabicLetter(runes[j]) ? runes[j] : null;
  }
  return null;
}

// Return the codepoint of the nearest Arabic letter after [i], skipping
// transparent characters.
int? _nextArabic(List<int> runes, int i) {
  for (int j = i + 1; j < runes.length; j++) {
    if (_isTransparent(runes[j])) continue;
    return _isArabicLetter(runes[j]) ? runes[j] : null;
  }
  return null;
}

// Return the INDEX of the nearest Arabic letter after [i], skipping
// transparent characters. Used for lam-alef ligature detection.
int? _nextArabicIndex(List<int> runes, int i) {
  for (int j = i + 1; j < runes.length; j++) {
    if (_isTransparent(runes[j])) continue;
    return _isArabicLetter(runes[j]) ? j : null;
  }
  return null;
}

// ── Lam-alef ligature data ────────────────────────────────────────────────────
//
// Maps the alef variant codepoint to [isolated_ligature, final_ligature].
// "isolated" = lam had no preceding connector; "final" = lam had a preceding
// D-type connector (lam was in final/medial position).

const Map<int, List<int>> _lamAlefForms = {
  0x0627: [0xFEFB, 0xFEFC], // ل + ا  → ﻻ / ﻼ
  0x0622: [0xFEF5, 0xFEF6], // ل + آ  → ﻵ / ﻶ
  0x0623: [0xFEF7, 0xFEF8], // ل + أ  → ﻷ / ﻸ
  0x0625: [0xFEF9, 0xFEFA], // ل + إ  → ﻹ / ﻺ
};

// ── Options ───────────────────────────────────────────────────────────────────

/// Options controlling optional reshape behaviours.
///
/// ```dart
/// // Default — no ligatures (safest for cross-platform terminals)
/// reshape(text);
///
/// // Opt-in lam-alef ligatures
/// reshape(text, options: ArabicReshapeOptions(useLamAlefLigatures: true));
/// ```
class ArabicReshapeOptions {
  /// When true, lam + alef sequences are replaced with their Unicode ligature
  /// forms (U+FEF5–U+FEFD).
  /// Use only when targeting terminals that render Presentation Forms.
  /// Default: false (cross-platform safe).
  final bool useLamAlefLigatures;

  const ArabicReshapeOptions({this.useLamAlefLigatures = false});

  static const ArabicReshapeOptions defaults = ArabicReshapeOptions();
}

// ── Public API ────────────────────────────────────────────────────────────────

/// Reshape Arabic text by replacing each canonical Arabic letter with its
/// contextual presentation form.
///
/// ## Form selection
/// ```
/// medial   = prevJoinsRight ∧ selfJoinsLeft ∧ selfJoinsRight ∧ nextJoinsLeft
/// final    = prevJoinsRight ∧ selfJoinsLeft ∧ ¬(selfJoinsRight ∧ nextJoinsLeft)
/// initial  = ¬prevJoinsRight ∧ selfJoinsRight ∧ nextJoinsLeft
/// isolated = otherwise
/// ```
///
/// Non-Arabic characters and tashkeel marks pass through unchanged.
/// Tashkeel (U+064B–U+065F) and tatweel (U+0640) are transparent for
/// joining purposes but are preserved in the output.
///
/// Pass [options] to enable lam-alef ligature substitution.
String reshape(String text,
    {ArabicReshapeOptions options = ArabicReshapeOptions.defaults}) {
  if (text.isEmpty) return text;
  final runes = text.runes.toList();
  final buf = StringBuffer();
  // Indices of alef characters consumed into lam-alef ligatures.
  final skipped = <int>{};

  for (int i = 0; i < runes.length; i++) {
    if (skipped.contains(i)) continue;

    final cp = runes[i];

    // Transparent and non-Arabic: pass through unchanged.
    if (_isTransparent(cp) || !_isArabicLetter(cp)) {
      buf.writeCharCode(cp);
      continue;
    }

    final forms = _forms[cp];
    if (forms == null) {
      // Rare/unknown Arabic letter — pass through unchanged.
      buf.writeCharCode(cp);
      continue;
    }

    // ء — U-type: no connecting forms, always isolated.
    if (cp == 0x0621) {
      buf.writeCharCode(forms[_iso]);
      continue;
    }

    // ── Lam-alef ligature check ──────────────────────────────────────────
    if (options.useLamAlefLigatures && cp == 0x0644) {
      final nextIdx = _nextArabicIndex(runes, i);
      if (nextIdx != null) {
        final nextCp = runes[nextIdx];
        final ligForms = _lamAlefForms[nextCp];
        if (ligForms != null) {
          final prev = _prevArabic(runes, i);
          final prevJR = prev != null && _joinsRight(prev);
          // Choose isolated or final ligature based on whether lam had a
          // preceding D-type connector.
          buf.writeCharCode(prevJR ? ligForms[1] : ligForms[0]);
          // Emit transparent chars between lam and alef (e.g. tashkeel on lam).
          for (int j = i + 1; j < nextIdx; j++) {
            buf.writeCharCode(runes[j]);
          }
          // Mark the alef as consumed.
          skipped.add(nextIdx);
          continue;
        }
      }
    }

    // ── Normal contextual form selection ─────────────────────────────────
    final prev = _prevArabic(runes, i);
    final next = _nextArabic(runes, i);

    final prevJR = prev != null && _joinsRight(prev);
    final nextJL = next != null && _joinsLeft(next);
    final selfJR = _joinsRight(cp);
    final selfJL = _joinsLeft(cp);

    final int idx;
    if (prevJR && selfJL && selfJR && nextJL) {
      idx = _med;
    } else if (prevJR && selfJL && !(selfJR && nextJL)) {
      idx = _fin;
    } else if (!prevJR && selfJR && nextJL) {
      idx = _ini;
    } else {
      idx = _iso;
    }

    final formCp = forms[idx];
    // 0 means no presentation form for this position (can happen for D-type
    // letters like ة whose ini/med forms don't exist); fall back to canonical.
    buf.writeCharCode(formCp != 0 ? formCp : cp);
  }

  return buf.toString();
}
