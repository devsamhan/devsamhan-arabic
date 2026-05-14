// Arabic letter reshaper — devsamhan-arabic spec v1.0.0
//
// Converts logical-order Arabic letters (U+0621–U+064A) to contextual
// Presentation Forms-B (U+FE70–U+FEFF) based on joining context.
//
// Form selection rules:
//   medial   = prevJoinsRight ∧ selfJoinsLeft ∧ selfJoinsRight ∧ nextJoinsLeft
//   final    = prevJoinsRight ∧ selfJoinsLeft ∧ ¬(selfJoinsRight ∧ nextJoinsLeft)
//   initial  = ¬prevJoinsRight ∧ selfJoinsRight ∧ nextJoinsLeft
//   isolated = otherwise

export interface ReshapeOptions {
  useLamAlefLigatures?: boolean; // default: false
}

const _ISO = 0, _FIN = 1, _INI = 2, _MED = 3;

// [isolated, final, initial, medial] — 0 = no form for that position
const FORMS: Readonly<Record<number, readonly [number, number, number, number]>> = {
  0x0621: [0xFE80, 0,      0,      0     ], // ء HAMZA — U-type
  0x0622: [0xFE81, 0xFE82, 0,      0     ], // آ ALEF MADDA — R-type
  0x0623: [0xFE83, 0xFE84, 0,      0     ], // أ ALEF HMZ ABOVE — R-type
  0x0624: [0xFE85, 0xFE86, 0,      0     ], // ؤ WAW HMZ — R-type
  0x0625: [0xFE87, 0xFE88, 0,      0     ], // إ ALEF HMZ BELOW — R-type
  0x0626: [0xFE89, 0xFE8A, 0xFE8B, 0xFE8C], // ئ YEH HMZ — D-type
  0x0627: [0xFE8D, 0xFE8E, 0,      0     ], // ا ALEF — R-type
  0x0628: [0xFE8F, 0xFE90, 0xFE91, 0xFE92], // ب BA — D-type
  0x0629: [0xFE93, 0xFE94, 0,      0     ], // ة TA MARBUTA — D-type (no ini/med)
  0x062A: [0xFE95, 0xFE96, 0xFE97, 0xFE98], // ت TA — D-type
  0x062B: [0xFE99, 0xFE9A, 0xFE9B, 0xFE9C], // ث THA — D-type
  0x062C: [0xFE9D, 0xFE9E, 0xFE9F, 0xFEA0], // ج JEEM — D-type
  0x062D: [0xFEA1, 0xFEA2, 0xFEA3, 0xFEA4], // ح HAH — D-type
  0x062E: [0xFEA5, 0xFEA6, 0xFEA7, 0xFEA8], // خ KHAH — D-type
  0x062F: [0xFEA9, 0xFEAA, 0,      0     ], // د DAL — R-type
  0x0630: [0xFEAB, 0xFEAC, 0,      0     ], // ذ THAL — R-type
  0x0631: [0xFEAD, 0xFEAE, 0,      0     ], // ر RA — R-type
  0x0632: [0xFEAF, 0xFEB0, 0,      0     ], // ز ZAIN — R-type
  0x0633: [0xFEB1, 0xFEB2, 0xFEB3, 0xFEB4], // س SEEN — D-type
  0x0634: [0xFEB5, 0xFEB6, 0xFEB7, 0xFEB8], // ش SHEEN — D-type
  0x0635: [0xFEB9, 0xFEBA, 0xFEBB, 0xFEBC], // ص SAD — D-type
  0x0636: [0xFEBD, 0xFEBE, 0xFEBF, 0xFEC0], // ض DAD — D-type
  0x0637: [0xFEC1, 0xFEC2, 0xFEC3, 0xFEC4], // ط TAH — D-type
  0x0638: [0xFEC5, 0xFEC6, 0xFEC7, 0xFEC8], // ظ ZAH — D-type
  0x0639: [0xFEC9, 0xFECA, 0xFECB, 0xFECC], // ع AIN — D-type
  0x063A: [0xFECD, 0xFECE, 0xFECF, 0xFED0], // غ GHAIN — D-type
  // U+063B–U+063F: rare/extended — no Presentation Forms-B; pass through
  // U+0640: tatweel — transparent; not in FORMS
  0x0641: [0xFED1, 0xFED2, 0xFED3, 0xFED4], // ف FA — D-type
  0x0642: [0xFED5, 0xFED6, 0xFED7, 0xFED8], // ق QAF — D-type
  0x0643: [0xFED9, 0xFEDA, 0xFEDB, 0xFEDC], // ك KAF — D-type
  0x0644: [0xFEDD, 0xFEDE, 0xFEDF, 0xFEE0], // ل LAM — D-type
  0x0645: [0xFEE1, 0xFEE2, 0xFEE3, 0xFEE4], // م MEEM — D-type
  0x0646: [0xFEE5, 0xFEE6, 0xFEE7, 0xFEE8], // ن NOON — D-type
  0x0647: [0xFEE9, 0xFEEA, 0xFEEB, 0xFEEC], // ه HEH — D-type
  0x0648: [0xFEED, 0xFEEE, 0,      0     ], // و WAW — R-type
  0x0649: [0xFEEF, 0xFEF0, 0,      0     ], // ى ALEF MAQSURA — R-type
  0x064A: [0xFEF1, 0xFEF2, 0xFEF3, 0xFEF4], // ي YEH — D-type
};

// R-type: joinsLeft only — accept connection from prev, cannot extend to next
const RIGHT_JOINING = new Set([
  0x0622, 0x0623, 0x0624, 0x0625, 0x0627,
  0x062F, 0x0630, 0x0631, 0x0632, 0x0648, 0x0649,
]);

// Maps alef variant → [isolated_ligature, final_ligature]
const LAM_ALEF_FORMS: Readonly<Record<number, readonly [number, number]>> = {
  0x0627: [0xFEFB, 0xFEFC], // ل + ا → ﻻ / ﻼ
  0x0622: [0xFEF5, 0xFEF6], // ل + آ → ﻵ / ﻶ
  0x0623: [0xFEF7, 0xFEF8], // ل + أ → ﻷ / ﻸ
  0x0625: [0xFEF9, 0xFEFA], // ل + إ → ﻹ / ﻺ
};

function isArabicLetter(cp: number): boolean {
  return (cp >= 0x0621 && cp <= 0x063A) || (cp >= 0x0641 && cp <= 0x064A);
}

function isTransparent(cp: number): boolean {
  return cp === 0x0640 || (cp >= 0x064B && cp <= 0x065F);
}

// D-type: extends a connection to the NEXT letter
function joinsRight(cp: number): boolean {
  return isArabicLetter(cp) && cp !== 0x0621 && !RIGHT_JOINING.has(cp);
}

// D-type or R-type: accepts a connection from the PREVIOUS letter
function joinsLeft(cp: number): boolean {
  return isArabicLetter(cp) && cp !== 0x0621;
}

function prevArabic(cps: number[], i: number): number | null {
  for (let j = i - 1; j >= 0; j--) {
    if (isTransparent(cps[j])) continue;
    return isArabicLetter(cps[j]) ? cps[j] : null;
  }
  return null;
}

function nextArabic(cps: number[], i: number): number | null {
  for (let j = i + 1; j < cps.length; j++) {
    if (isTransparent(cps[j])) continue;
    return isArabicLetter(cps[j]) ? cps[j] : null;
  }
  return null;
}

function nextArabicIndex(cps: number[], i: number): number | null {
  for (let j = i + 1; j < cps.length; j++) {
    if (isTransparent(cps[j])) continue;
    return isArabicLetter(cps[j]) ? j : null;
  }
  return null;
}

export function reshape(text: string, options?: ReshapeOptions): string {
  if (!text) return text;
  const useLig = options?.useLamAlefLigatures ?? false;
  const cps: number[] = [];
  for (const ch of text) cps.push(ch.codePointAt(0)!);

  const skipped = new Set<number>();
  let result = '';

  for (let i = 0; i < cps.length; i++) {
    if (skipped.has(i)) continue;
    const cp = cps[i];

    if (isTransparent(cp) || !isArabicLetter(cp)) {
      result += String.fromCodePoint(cp);
      continue;
    }

    const forms = FORMS[cp];
    if (forms === undefined) {
      result += String.fromCodePoint(cp);
      continue;
    }

    // ء — U-type: always isolated
    if (cp === 0x0621) {
      result += String.fromCodePoint(forms[_ISO]);
      continue;
    }

    // Lam-alef ligature check
    if (useLig && cp === 0x0644) {
      const nextIdx = nextArabicIndex(cps, i);
      if (nextIdx !== null) {
        const nextCp = cps[nextIdx];
        const ligForms = LAM_ALEF_FORMS[nextCp];
        if (ligForms !== undefined) {
          const prev = prevArabic(cps, i);
          const prevJR = prev !== null && joinsRight(prev);
          result += String.fromCodePoint(prevJR ? ligForms[1] : ligForms[0]);
          // Emit any transparent chars between lam and alef
          for (let j = i + 1; j < nextIdx; j++) result += String.fromCodePoint(cps[j]);
          skipped.add(nextIdx);
          continue;
        }
      }
    }

    // Normal contextual form selection
    const prev = prevArabic(cps, i);
    const next = nextArabic(cps, i);
    const prevJR = prev !== null && joinsRight(prev);
    const nextJL = next !== null && joinsLeft(next);
    const selfJR = joinsRight(cp);
    const selfJL = joinsLeft(cp);

    let idx: number;
    if      (prevJR && selfJL && selfJR && nextJL)          idx = _MED;
    else if (prevJR && selfJL && !(selfJR && nextJL))        idx = _FIN;
    else if (!prevJR && selfJR && nextJL)                    idx = _INI;
    else                                                      idx = _ISO;

    const formCp = forms[idx];
    result += String.fromCodePoint(formCp !== 0 ? formCp : cp);
  }

  return result;
}
