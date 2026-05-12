/// Arabic text normalization functions — devsamhan-arabic spec v1.0.0
library;

// ── Spec version ──────────────────────────────────────────────────────────────

/// Must match the SPEC.md version field. All conformant implementations must
/// expose this constant.
const String specVersion = '1.0.0';

// ── normalizeTaMarbouta ───────────────────────────────────────────────────────

/// Convert Ta Marbouta (ة U+0629) to Ha (ه U+0647).
///
/// MUST be called explicitly — never applied automatically by any preset
/// except toSlug.
String normalizeTaMarbouta(String text) => text.replaceAll('ة', 'ه');

// ── normalizeYa ───────────────────────────────────────────────────────────────

/// Normalize Alef Maqsoura (ى U+0649) and Persian/Urdu Yeh (ی U+06CC) to
/// Arabic Yeh (ي U+064A).
String normalizeYa(String text) => text
    .replaceAll('ى', 'ي') // U+0649 → U+064A
    .replaceAll('ی', 'ي'); // U+06CC → U+064A

// ── normalizeHamza ────────────────────────────────────────────────────────────

/// Normalize hamza-on-waw (ؤ U+0624) and hamza-on-ya (ئ U+0626) to bare
/// hamza (ء U+0621).  Does NOT touch أ/إ — those are handled by normalizeAlef.
String normalizeHamza(String text) => text
    .replaceAll('ؤ', 'ء') // U+0624 → U+0621
    .replaceAll('ئ', 'ء'); // U+0626 → U+0621

// ── normalizeAlef ─────────────────────────────────────────────────────────────

/// Normalize Alef variants to bare Alef (ا U+0627).
///
/// Handles: أ (U+0623), إ (U+0625), آ (U+0622), ٱ (U+0671).
String normalizeAlef(String text) => text
    .replaceAll('أ', 'ا') // U+0623 → U+0627
    .replaceAll('إ', 'ا') // U+0625 → U+0627
    .replaceAll('آ', 'ا') // U+0622 → U+0627
    .replaceAll('ٱ', 'ا'); // U+0671 → U+0627

// ── removeTatweel ─────────────────────────────────────────────────────────────

/// Remove tatweel / kashida (U+0640) from [text].
///
/// The sequence U+0640 + U+0670 (tatweel + superscript alef) is preserved
/// because U+0670 is a Quranic annotation sign that uses the tatweel as its
/// base carrier — stripping U+0640 there would corrupt the annotation.
String removeTatweel(String text) => text.replaceAll(RegExp('ـ(?!ٰ)'), '');

// ── removeTashkeel ────────────────────────────────────────────────────────────

/// Remove all Arabic diacritics (tashkeel) from [text].
///
/// Ranges removed per spec:
///   U+064B–U+065F  main vowel marks / shadda / sukun
///   U+0610–U+061A  extended Arabic signs
///   U+06D6–U+06DC  Quranic annotation signs
///   U+06DF–U+06E4  more Quranic signs
///   U+06E7–U+06E8  Quranic yeh / waw marks
///   U+06EA–U+06ED  Quranic marks
String removeTashkeel(String text) => text.replaceAll(_tashkeelRe, '');

final _tashkeelRe = RegExp(
  r'[ً-ٟؐ-ؚۖ-ۜ۟-۪ۤۧۨ-ۭ]',
);

// ── normalizePresentationForms ────────────────────────────────────────────────

/// Convert Arabic Presentation Forms (U+FB50–U+FDFF, U+FE70–U+FEFF) to
/// their canonical Unicode equivalents.
String normalizePresentationForms(String text) {
  if (text.isEmpty) return text;
  final buf = StringBuffer();
  for (final rune in text.runes) {
    final mapped = _presentationFormsMap[rune];
    if (mapped != null) {
      buf.write(mapped);
    } else {
      buf.writeCharCode(rune);
    }
  }
  return buf.toString();
}

// ── _presentationFormsMap ────────────────────────────────────────────────────
// Maps each Arabic Presentation Form code point to its canonical string.
// Sources: Unicode 15 decomposition data, UnicodeData.txt.

const Map<int, String> _presentationFormsMap = {
  // ── Arabic Presentation Forms-B (U+FE70–U+FEFC) ────────────────────────────
  // Spacing forms of diacritics
  0xFE70: ' ً', // ARABIC FATHATAN ISOLATED FORM
  0xFE71: 'ـً', // ARABIC TATWEEL WITH FATHATAN ABOVE
  0xFE72: ' ٌ', // ARABIC DAMMATAN ISOLATED FORM
  0xFE74: ' ٍ', // ARABIC KASRATAN ISOLATED FORM
  0xFE76: ' َ', // ARABIC FATHA ISOLATED FORM
  0xFE77: 'ـَ', // ARABIC FATHA MEDIAL FORM
  0xFE78: ' ُ', // ARABIC DAMMA ISOLATED FORM
  0xFE79: 'ـُ', // ARABIC DAMMA MEDIAL FORM
  0xFE7A: ' ِ', // ARABIC KASRA ISOLATED FORM
  0xFE7B: 'ـِ', // ARABIC KASRA MEDIAL FORM
  0xFE7C: ' ّ', // ARABIC SHADDA ISOLATED FORM
  0xFE7D: 'ـّ', // ARABIC SHADDA MEDIAL FORM
  0xFE7E: ' ْ', // ARABIC SUKUN ISOLATED FORM
  0xFE7F: 'ـْ', // ARABIC SUKUN MEDIAL FORM
  // Letter forms — isolated/final/initial/medial all map to the same base char
  0xFE80: 'ء', // HAMZA
  0xFE81: 'آ', // ALEF WITH MADDA ABOVE
  0xFE82: 'آ',
  0xFE83: 'أ', // ALEF WITH HAMZA ABOVE
  0xFE84: 'أ',
  0xFE85: 'ؤ', // WAW WITH HAMZA ABOVE
  0xFE86: 'ؤ',
  0xFE87: 'إ', // ALEF WITH HAMZA BELOW
  0xFE88: 'إ',
  0xFE89: 'ئ', // YEH WITH HAMZA ABOVE
  0xFE8A: 'ئ',
  0xFE8B: 'ئ',
  0xFE8C: 'ئ',
  0xFE8D: 'ا', // ALEF
  0xFE8E: 'ا',
  0xFE8F: 'ب', // BA
  0xFE90: 'ب',
  0xFE91: 'ب',
  0xFE92: 'ب',
  0xFE93: 'ة', // TA MARBUTA
  0xFE94: 'ة',
  0xFE95: 'ت', // TA
  0xFE96: 'ت',
  0xFE97: 'ت',
  0xFE98: 'ت',
  0xFE99: 'ث', // THA
  0xFE9A: 'ث',
  0xFE9B: 'ث',
  0xFE9C: 'ث',
  0xFE9D: 'ج', // JEEM
  0xFE9E: 'ج',
  0xFE9F: 'ج',
  0xFEA0: 'ج',
  0xFEA1: 'ح', // HAH
  0xFEA2: 'ح',
  0xFEA3: 'ح',
  0xFEA4: 'ح',
  0xFEA5: 'خ', // KHAH
  0xFEA6: 'خ',
  0xFEA7: 'خ',
  0xFEA8: 'خ',
  0xFEA9: 'د', // DAL
  0xFEAA: 'د',
  0xFEAB: 'ذ', // THAL
  0xFEAC: 'ذ',
  0xFEAD: 'ر', // RA
  0xFEAE: 'ر',
  0xFEAF: 'ز', // ZAIN
  0xFEB0: 'ز',
  0xFEB1: 'س', // SEEN
  0xFEB2: 'س',
  0xFEB3: 'س',
  0xFEB4: 'س',
  0xFEB5: 'ش', // SHEEN
  0xFEB6: 'ش',
  0xFEB7: 'ش',
  0xFEB8: 'ش',
  0xFEB9: 'ص', // SAD
  0xFEBA: 'ص',
  0xFEBB: 'ص',
  0xFEBC: 'ص',
  0xFEBD: 'ض', // DAD
  0xFEBE: 'ض',
  0xFEBF: 'ض',
  0xFEC0: 'ض',
  0xFEC1: 'ط', // TAH
  0xFEC2: 'ط',
  0xFEC3: 'ط',
  0xFEC4: 'ط',
  0xFEC5: 'ظ', // ZAH
  0xFEC6: 'ظ',
  0xFEC7: 'ظ',
  0xFEC8: 'ظ',
  0xFEC9: 'ع', // AIN
  0xFECA: 'ع',
  0xFECB: 'ع',
  0xFECC: 'ع',
  0xFECD: 'غ', // GHAIN
  0xFECE: 'غ',
  0xFECF: 'غ',
  0xFED0: 'غ',
  0xFED1: 'ف', // FA
  0xFED2: 'ف',
  0xFED3: 'ف',
  0xFED4: 'ف',
  0xFED5: 'ق', // QAF
  0xFED6: 'ق',
  0xFED7: 'ق',
  0xFED8: 'ق',
  0xFED9: 'ك', // KAF
  0xFEDA: 'ك',
  0xFEDB: 'ك',
  0xFEDC: 'ك',
  0xFEDD: 'ل', // LAM
  0xFEDE: 'ل',
  0xFEDF: 'ل',
  0xFEE0: 'ل',
  0xFEE1: 'م', // MEEM
  0xFEE2: 'م',
  0xFEE3: 'م',
  0xFEE4: 'م',
  0xFEE5: 'ن', // NOON
  0xFEE6: 'ن',
  0xFEE7: 'ن',
  0xFEE8: 'ن',
  0xFEE9: 'ه', // HEH
  0xFEEA: 'ه',
  0xFEEB: 'ه',
  0xFEEC: 'ه',
  0xFEED: 'و', // WAW
  0xFEEE: 'و',
  0xFEEF: 'ى', // ALEF MAQSURA
  0xFEF0: 'ى',
  0xFEF1: 'ي', // YEH
  0xFEF2: 'ي',
  0xFEF3: 'ي',
  0xFEF4: 'ي',
  // Lam-alef ligatures
  0xFEF5: 'لآ', // LAM + ALEF WITH MADDA ABOVE
  0xFEF6: 'لآ',
  0xFEF7: 'لأ', // LAM + ALEF WITH HAMZA ABOVE
  0xFEF8: 'لأ',
  0xFEF9: 'لإ', // LAM + ALEF WITH HAMZA BELOW
  0xFEFA: 'لإ',
  0xFEFB: 'لا', // LAM + ALEF
  0xFEFC: 'لا',

  // ── Arabic Presentation Forms-A (U+FB50–U+FDFF) ────────────────────────────
  // Extended letter forms (Urdu, Persian, etc.)
  0xFB50: 'ٱ', 0xFB51: 'ٱ', // ALEF WASLA
  0xFB52: 'ٻ', 0xFB53: 'ٻ', 0xFB54: 'ٻ',
  0xFB55: 'ٻ', // BA WITH THREE DOTS POINTING DOWN
  0xFB56: 'پ', 0xFB57: 'پ', 0xFB58: 'پ', 0xFB59: 'پ', // PE
  0xFB5A: 'ڀ', 0xFB5B: 'ڀ', 0xFB5C: 'ڀ', 0xFB5D: 'ڀ',
  0xFB5E: 'ٺ', 0xFB5F: 'ٺ', 0xFB60: 'ٺ', 0xFB61: 'ٺ',
  0xFB62: 'ٿ', 0xFB63: 'ٿ', 0xFB64: 'ٿ', 0xFB65: 'ٿ',
  0xFB66: 'ٹ', 0xFB67: 'ٹ', 0xFB68: 'ٹ', 0xFB69: 'ٹ', // TTEH
  0xFB6A: 'ڤ', 0xFB6B: 'ڤ', 0xFB6C: 'ڤ', 0xFB6D: 'ڤ', // VEH
  0xFB6E: 'ڦ', 0xFB6F: 'ڦ', 0xFB70: 'ڦ', 0xFB71: 'ڦ',
  0xFB72: 'ڄ', 0xFB73: 'ڄ', 0xFB74: 'ڄ', 0xFB75: 'ڄ',
  0xFB76: 'ڃ', 0xFB77: 'ڃ', 0xFB78: 'ڃ', 0xFB79: 'ڃ',
  0xFB7A: 'چ', 0xFB7B: 'چ', 0xFB7C: 'چ', 0xFB7D: 'چ', // TCHEH
  0xFB7E: 'ڇ', 0xFB7F: 'ڇ', 0xFB80: 'ڇ', 0xFB81: 'ڇ',
  0xFB82: 'ڍ', 0xFB83: 'ڍ',
  0xFB84: 'ڌ', 0xFB85: 'ڌ',
  0xFB86: 'ڎ', 0xFB87: 'ڎ',
  0xFB88: 'ڈ', 0xFB89: 'ڈ', // DDAL
  0xFB8A: 'ژ', 0xFB8B: 'ژ', // JEH
  0xFB8C: 'ڑ', 0xFB8D: 'ڑ', // RREH
  0xFB8E: 'ک', 0xFB8F: 'ک', 0xFB90: 'ک', 0xFB91: 'ک', // KEHEH
  0xFB92: 'گ', 0xFB93: 'گ', 0xFB94: 'گ', 0xFB95: 'گ', // GAF
  0xFB96: 'ڳ', 0xFB97: 'ڳ', 0xFB98: 'ڳ', 0xFB99: 'ڳ',
  0xFB9A: 'ڱ', 0xFB9B: 'ڱ', 0xFB9C: 'ڱ', 0xFB9D: 'ڱ',
  0xFB9E: 'ں', 0xFB9F: 'ں', // NOON GHUNNA
  0xFBA0: 'ڻ', 0xFBA1: 'ڻ', 0xFBA2: 'ڻ', 0xFBA3: 'ڻ',
  0xFBA4: 'ۀ', 0xFBA5: 'ۀ', // HEH WITH YEH ABOVE
  0xFBA6: 'ہ', 0xFBA7: 'ہ', 0xFBA8: 'ہ', 0xFBA9: 'ہ', // HEH GOAL
  0xFBAA: 'ھ', 0xFBAB: 'ھ', 0xFBAC: 'ھ', 0xFBAD: 'ھ', // HEH DOACHASHMEE
  0xFBAE: 'ے', 0xFBAF: 'ے', // YEH BARREE
  0xFBB0: 'ۓ', 0xFBB1: 'ۓ', // YEH BARREE WITH HAMZA ABOVE
  // FBB2-FBD2: not assigned or diacritic marks (skip)
  0xFBD3: 'ڭ', 0xFBD4: 'ڭ', 0xFBD5: 'ڭ', 0xFBD6: 'ڭ', // NG
  0xFBD7: 'ۇ', 0xFBD8: 'ۇ', // U
  0xFBD9: 'ۆ', 0xFBDA: 'ۆ', // OE
  0xFBDB: 'ۈ', 0xFBDC: 'ۈ', // YU
  0xFBDD: 'ٷ', // U WITH HAMZA ABOVE
  0xFBDE: 'ۋ', 0xFBDF: 'ۋ', // VE
  0xFBE0: 'ۅ', 0xFBE1: 'ۅ', // KIRGHIZ OE
  0xFBE2: 'ۉ', 0xFBE3: 'ۉ', // KIRGHIZ YU
  0xFBE4: 'ې', 0xFBE5: 'ې', 0xFBE6: 'ې', 0xFBE7: 'ې',
  0xFBE8: 'ى', 0xFBE9: 'ى', // HIGH HAMZA YEH
  0xFBEA: 'ئا', 0xFBEB: 'ئا', // YEH WITH HAMZA + ALEF
  0xFBEC: 'ئە', 0xFBED: 'ئە',
  0xFBEE: 'ئو', 0xFBEF: 'ئو', // YEH WITH HAMZA + WAW
  0xFBF0: 'ئۇ', 0xFBF1: 'ئۇ',
  0xFBF2: 'ئۆ', 0xFBF3: 'ئۆ',
  0xFBF4: 'ئۈ', 0xFBF5: 'ئۈ',
  0xFBF6: 'ئې', 0xFBF7: 'ئې', 0xFBF8: 'ئې',
  0xFBF9: 'ئی', 0xFBFA: 'ئی', 0xFBFB: 'ئی',
  0xFBFC: 'ی', 0xFBFD: 'ی', 0xFBFE: 'ی', 0xFBFF: 'ی',
  // Special ligatures
  0xFDF2: 'الله', // ARABIC LIGATURE ALLAH = الله
  0xFDFA: 'صلى الله عليه وسلم', // ﷺ
  0xFDFB: 'جل جلاله', // ﷻ
};

// ── normalizeDigits ───────────────────────────────────────────────────────────

/// Convert digits between Eastern Arabic / Persian and Western forms.
///
/// [to] must be `'western'` or `'eastern'`.
///
/// Eastern Arabic (U+0660–U+0669) and Extended Persian (U+06F0–U+06F9) are
/// both treated as source forms for `to: 'western'`.
/// Only Western digits (0–9) are converted for `to: 'eastern'`.
String normalizeDigits(String text, {required String to}) {
  switch (to) {
    case 'western':
      return text.replaceAllMapped(
        RegExp('[٠-٩۰-۹]'),
        (m) {
          final cp = m[0]!.codeUnitAt(0);
          final base = cp <= 0x0669 ? 0x0660 : 0x06F0;
          return String.fromCharCode(0x30 + (cp - base));
        },
      );
    case 'eastern':
      return text.replaceAllMapped(
        RegExp(r'[0-9]'),
        (m) => String.fromCharCode(0x0660 + m[0]!.codeUnitAt(0) - 0x30),
      );
    default:
      return text;
  }
}
