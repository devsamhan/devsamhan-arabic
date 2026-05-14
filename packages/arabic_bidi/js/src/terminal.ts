// Arabic terminal preparation — devsamhan-arabic spec v1.0.0

import { reshape, ReshapeOptions } from './reshaper';

// Counts letters U+0621–U+063A and U+0641–U+064A divided by non-whitespace
// chars. Mirrors the Python/Dart definition; Eastern Arabic digits are excluded.
function arabicLetterRatio(text: string): number {
  const chars = [...text].filter((c) => c.trim() !== '');
  if (chars.length === 0) return 0;
  let letters = 0;
  for (const c of chars) {
    const cp = c.codePointAt(0)!;
    if ((cp >= 0x0621 && cp <= 0x063A) || (cp >= 0x0641 && cp <= 0x064A)) {
      letters++;
    }
  }
  return letters / chars.length;
}

export interface TerminalOptions {
  reshape?: boolean;              // default: true
  reorder?: boolean;              // default: true
  useLamAlefLigatures?: boolean;  // default: false
}

export enum Direction {
  RTL = 'rtl',
  LTR = 'ltr',
  MIXED = 'mixed',
}

type RunType = 'arabic' | 'latin' | 'number' | 'space' | 'punctuation';

interface Run {
  type: RunType;
  text: string;
}

function classify(cp: number): RunType {
  // Arabic letters U+0621–U+063A, tatweel U+0640, tashkeel U+064B–U+065F
  if (cp >= 0x0621 && cp <= 0x065F) return 'arabic';
  if ((cp >= 0x41 && cp <= 0x5A) || (cp >= 0x61 && cp <= 0x7A)) return 'latin';
  // ASCII 0–9, Eastern Arabic U+0660–U+0669, Persian U+06F0–U+06F9
  if ((cp >= 0x30 && cp <= 0x39) || (cp >= 0x0660 && cp <= 0x0669) || (cp >= 0x06F0 && cp <= 0x06F9)) return 'number';
  if (cp === 0x20 || cp === 0x09 || cp === 0x0A || cp === 0x0D) return 'space';
  return 'punctuation';
}

function splitRuns(text: string): Run[] {
  if (!text) return [];
  const cps: number[] = [];
  for (const ch of text) cps.push(ch.codePointAt(0)!);

  const runs: Run[] = [];
  let currentType = classify(cps[0]);
  let start = 0;

  for (let i = 1; i < cps.length; i++) {
    const t = classify(cps[i]);
    if (t !== currentType) {
      runs.push({ type: currentType, text: String.fromCodePoint(...cps.slice(start, i)) });
      start = i;
      currentType = t;
    }
  }
  runs.push({ type: currentType, text: String.fromCodePoint(...cps.slice(start)) });
  return runs;
}

export function prepareForTerminal(text: string, options?: TerminalOptions): string {
  if (!text) return text;
  const doReshape = options?.reshape ?? true;
  const doReorder = options?.reorder ?? true;
  const useLig = options?.useLamAlefLigatures ?? false;

  const runs = splitRuns(text);

  const reshaped = doReshape
    ? runs.map(run => {
        if (run.type !== 'arabic') return run;
        return { type: run.type, text: reshape(run.text, { useLamAlefLigatures: useLig }) };
      })
    : runs;

  // Reorder when Arabic letters are strict majority of non-whitespace chars.
  const ordered = doReorder && arabicLetterRatio(text) > 0.5
    ? [...reshaped].reverse()
    : reshaped;

  return ordered.map(r => r.text).join('');
}

export function printArabic(text: string, options?: TerminalOptions): void {
  console.log(prepareForTerminal(text, options));
}

// detectDirection — mirrors Dart's ArabicBidi.detectDirection.
// Counts Arabic-block (U+0600–U+06FF) vs Basic Latin (A–Z, a–z).
// Returns RTL if Arabic ≥ 80% of (arabic+latin), LTR if Latin ≥ 80%, MIXED otherwise.
export function detectDirection(text: string): Direction {
  if (!text) return Direction.LTR;
  let arabic = 0, latin = 0;
  for (const ch of text) {
    const cp = ch.codePointAt(0)!;
    if (cp >= 0x0600 && cp <= 0x06FF) arabic++;
    if ((cp >= 0x41 && cp <= 0x5A) || (cp >= 0x61 && cp <= 0x7A)) latin++;
  }
  const total = arabic + latin;
  if (total === 0) return Direction.LTR;
  if (arabic / total >= 0.8) return Direction.RTL;
  if (latin / total >= 0.8) return Direction.LTR;
  return Direction.MIXED;
}

// Convenience alias used by ArabicBidi facade (matches Dart's isRTL)
export function isRTL(text: string): boolean {
  return detectDirection(text) === Direction.RTL;
}
