// Arabic text normalization functions — devsamhan-arabic spec v1.0.0

export const specVersion = '1.0.0';

// ── removeTashkeel ────────────────────────────────────────────────────────────
// Ranges per spec:
//   U+064B–U+065F  main vowel marks / shadda / sukun
//   U+0610–U+061A  extended Arabic signs
//   U+06D6–U+06DC  Quranic annotation signs
//   U+06DF–U+06ED  Quranic marks (combined range covering all spec sub-ranges)
const TASHKEEL_RE = /[ً-ٟؐ-ؚۖ-ۜ۟-ۭ]/g;

export function removeTashkeel(text: string): string {
  return text.replace(TASHKEEL_RE, '');
}

// ── removeTatweel ─────────────────────────────────────────────────────────────
// Preserves U+0640 + U+0670 (tatweel + superscript alef) — Quranic annotation.
export function removeTatweel(text: string): string {
  return text.replace(/ـ(?!ٰ)/g, '');
}

// ── normalizeAlef ─────────────────────────────────────────────────────────────
// أ (U+0623), إ (U+0625), آ (U+0622), ٱ (U+0671) → ا (U+0627)
export function normalizeAlef(text: string): string {
  return text
    .replace(/أ/g, 'ا')
    .replace(/إ/g, 'ا')
    .replace(/آ/g, 'ا')
    .replace(/ٱ/g, 'ا');
}

// ── normalizeHamza ────────────────────────────────────────────────────────────
// ؤ (U+0624) → ء (U+0621), ئ (U+0626) → ء (U+0621)
// Does NOT touch أ / إ — those are handled by normalizeAlef.
export function normalizeHamza(text: string): string {
  return text
    .replace(/ؤ/g, 'ء')
    .replace(/ئ/g, 'ء');
}

// ── normalizeYa ───────────────────────────────────────────────────────────────
// ى (U+0649 alef maqsoura) → ي (U+064A)
// ی (U+06CC Persian/Urdu Yeh) → ي (U+064A)
export function normalizeYa(text: string): string {
  return text
    .replace(/ى/g, 'ي')
    .replace(/ی/g, 'ي');
}

// ── normalizeTaMarbouta ───────────────────────────────────────────────────────
// ة (U+0629) → ه (U+0647)
// MUST be called explicitly — never applied automatically by any preset except toSlug.
export function normalizeTaMarbouta(text: string): string {
  return text.replace(/ة/g, 'ه');
}

// ── normalizeDigits ───────────────────────────────────────────────────────────
// Eastern Arabic (U+0660–U+0669) and Persian (U+06F0–U+06F9) → Western 0–9
// Western 0–9 → Eastern Arabic (U+0660–U+0669)
export function normalizeDigits(text: string, to: 'western' | 'eastern'): string {
  if (to === 'western') {
    return text.replace(/[٠-٩۰-۹]/g, (ch) => {
      const cp = ch.charCodeAt(0);
      const base = cp <= 0x0669 ? 0x0660 : 0x06F0;
      return String.fromCharCode(0x30 + (cp - base));
    });
  } else {
    return text.replace(/[0-9]/g, (ch) =>
      String.fromCharCode(0x0660 + ch.charCodeAt(0) - 0x30)
    );
  }
}

// ── normalizePresentationForms ────────────────────────────────────────────────
// Convert Arabic Presentation Forms (U+FB50–U+FDFF, U+FE70–U+FEFF) to
// their canonical Unicode equivalents.
export function normalizePresentationForms(text: string): string {
  if (!text) return text;
  let result = '';
  for (let i = 0; i < text.length; i++) {
    const cp = text.charCodeAt(i);
    const mapped = PRESENTATION_FORMS_MAP[cp];
    result += mapped !== undefined ? mapped : text[i];
  }
  return result;
}

// ── isArabic / arabicRatio ────────────────────────────────────────────────────

export function isArabic(text: string): boolean {
  return /[؀-ۿ]/.test(text);
}

export function arabicRatio(text: string): number {
  if (!text) return 0.0;
  let arabic = 0;
  for (let i = 0; i < text.length; i++) {
    const cp = text.charCodeAt(i);
    if (cp >= 0x0600 && cp <= 0x06FF) arabic++;
  }
  return arabic / text.length;
}

// ── _presentationFormsMap ─────────────────────────────────────────────────────
// Maps each Arabic Presentation Form code point to its canonical string.
// Source: Unicode 15 decomposition data, UnicodeData.txt.

const PRESENTATION_FORMS_MAP: Record<number, string> = {
  // ── Arabic Presentation Forms-B (U+FE70–U+FEFC) ───────────────────────────
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
  // Letter forms
  0xFE80: 'ء', // HAMZA
  0xFE81: 'آ', 0xFE82: 'آ', // ALEF WITH MADDA ABOVE
  0xFE83: 'أ', 0xFE84: 'أ', // ALEF WITH HAMZA ABOVE
  0xFE85: 'ؤ', 0xFE86: 'ؤ', // WAW WITH HAMZA ABOVE
  0xFE87: 'إ', 0xFE88: 'إ', // ALEF WITH HAMZA BELOW
  0xFE89: 'ئ', 0xFE8A: 'ئ', 0xFE8B: 'ئ', 0xFE8C: 'ئ', // YEH WITH HAMZA ABOVE
  0xFE8D: 'ا', 0xFE8E: 'ا', // ALEF
  0xFE8F: 'ب', 0xFE90: 'ب', 0xFE91: 'ب', 0xFE92: 'ب', // BA
  0xFE93: 'ة', 0xFE94: 'ة', // TA MARBUTA
  0xFE95: 'ت', 0xFE96: 'ت', 0xFE97: 'ت', 0xFE98: 'ت', // TA
  0xFE99: 'ث', 0xFE9A: 'ث', 0xFE9B: 'ث', 0xFE9C: 'ث', // THA
  0xFE9D: 'ج', 0xFE9E: 'ج', 0xFE9F: 'ج', 0xFEA0: 'ج', // JEEM
  0xFEA1: 'ح', 0xFEA2: 'ح', 0xFEA3: 'ح', 0xFEA4: 'ح', // HAH
  0xFEA5: 'خ', 0xFEA6: 'خ', 0xFEA7: 'خ', 0xFEA8: 'خ', // KHAH
  0xFEA9: 'د', 0xFEAA: 'د', // DAL
  0xFEAB: 'ذ', 0xFEAC: 'ذ', // THAL
  0xFEAD: 'ر', 0xFEAE: 'ر', // RA
  0xFEAF: 'ز', 0xFEB0: 'ز', // ZAIN
  0xFEB1: 'س', 0xFEB2: 'س', 0xFEB3: 'س', 0xFEB4: 'س', // SEEN
  0xFEB5: 'ش', 0xFEB6: 'ش', 0xFEB7: 'ش', 0xFEB8: 'ش', // SHEEN
  0xFEB9: 'ص', 0xFEBA: 'ص', 0xFEBB: 'ص', 0xFEBC: 'ص', // SAD
  0xFEBD: 'ض', 0xFEBE: 'ض', 0xFEBF: 'ض', 0xFEC0: 'ض', // DAD
  0xFEC1: 'ط', 0xFEC2: 'ط', 0xFEC3: 'ط', 0xFEC4: 'ط', // TAH
  0xFEC5: 'ظ', 0xFEC6: 'ظ', 0xFEC7: 'ظ', 0xFEC8: 'ظ', // ZAH
  0xFEC9: 'ع', 0xFECA: 'ع', 0xFECB: 'ع', 0xFECC: 'ع', // AIN
  0xFECD: 'غ', 0xFECE: 'غ', 0xFECF: 'غ', 0xFED0: 'غ', // GHAIN
  0xFED1: 'ف', 0xFED2: 'ف', 0xFED3: 'ف', 0xFED4: 'ف', // FA
  0xFED5: 'ق', 0xFED6: 'ق', 0xFED7: 'ق', 0xFED8: 'ق', // QAF
  0xFED9: 'ك', 0xFEDA: 'ك', 0xFEDB: 'ك', 0xFEDC: 'ك', // KAF
  0xFEDD: 'ل', 0xFEDE: 'ل', 0xFEDF: 'ل', 0xFEE0: 'ل', // LAM
  0xFEE1: 'م', 0xFEE2: 'م', 0xFEE3: 'م', 0xFEE4: 'م', // MEEM
  0xFEE5: 'ن', 0xFEE6: 'ن', 0xFEE7: 'ن', 0xFEE8: 'ن', // NOON
  0xFEE9: 'ه', 0xFEEA: 'ه', 0xFEEB: 'ه', 0xFEEC: 'ه', // HEH
  0xFEED: 'و', 0xFEEE: 'و', // WAW
  0xFEEF: 'ى', 0xFEF0: 'ى', // ALEF MAQSURA
  0xFEF1: 'ي', 0xFEF2: 'ي', 0xFEF3: 'ي', 0xFEF4: 'ي', // YEH
  // Lam-alef ligatures
  0xFEF5: 'لآ', 0xFEF6: 'لآ', // LAM + ALEF WITH MADDA ABOVE
  0xFEF7: 'لأ', 0xFEF8: 'لأ', // LAM + ALEF WITH HAMZA ABOVE
  0xFEF9: 'لإ', 0xFEFA: 'لإ', // LAM + ALEF WITH HAMZA BELOW
  0xFEFB: 'لا', 0xFEFC: 'لا', // LAM + ALEF

  // ── Arabic Presentation Forms-A (U+FB50–U+FBFF) ───────────────────────────
  0xFB50: 'ٱ', 0xFB51: 'ٱ', // ALEF WASLA
  0xFB52: 'ٻ', 0xFB53: 'ٻ', 0xFB54: 'ٻ', 0xFB55: 'ٻ', // BA WITH THREE DOTS
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
