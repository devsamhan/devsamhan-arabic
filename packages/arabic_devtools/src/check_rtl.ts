import { Finding } from './types';

// Keys are the reversed/suspicious forms found in files.
// Values are the corrected logical Arabic forms (suggestion).
// Direction: found = key (wrong), suggestion = value (correct).
const KNOWN_REVERSALS: Record<string, string> = {
  ثحب: 'بحث', // U+062B U+062D U+0628 → U+0628 U+062D U+062B  ("search" reversed → correct)
  دمحم: 'محمد', // U+062F U+0645 U+062D U+0645 → U+0645 U+062D U+0645 U+062F  ("Muhammad" reversed → correct)
  تادادعإ: 'إعدادات', // "settings" reversed → correct
  فلم: 'ملف', // "file" reversed → correct
  ظفح: 'حفظ', // "save" reversed → correct
};

function isArabicChar(cp: number): boolean {
  return (cp >= 0x0621 && cp <= 0x063a) || (cp >= 0x0641 && cp <= 0x064a);
}

function isArabicWord(word: string): boolean {
  return [...word].some((c) => isArabicChar(c.codePointAt(0)!));
}

export function detectReversedInText(text: string, file: string): Finding[] {
  const findings: Finding[] = [];
  const lines = text.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const lineNum = i + 1;
    // Arabic character-only regex: strips surrounding punctuation/quotes so that
    // Arabic inside code string literals ('ثحب', "ثحب";) is extracted correctly.
    // Ranges: U+0600-06FF (Arabic), U+0750-077F (Supplement),
    //         U+FB50-FDFF (Pres. Forms-A), U+FE70-FEFF (Pres. Forms-B).
    const wordRegex = /[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]+/g;
    let match: RegExpExecArray | null;

    while ((match = wordRegex.exec(lines[i])) !== null) {
      const word = match[0];
      const column = match.index + 1;

      if (!isArabicWord(word)) continue;

      if (KNOWN_REVERSALS[word] !== undefined) {
        findings.push({
          code: 'AR001',
          type: 'potentially-reversed-arabic-literal',
          severity: 'high',
          file,
          line: lineNum,
          column,
          found: word,
          suggestion: KNOWN_REVERSALS[word],
          message: 'Potentially reversed Arabic literal',
        });
        continue;
      }

      const chars = [...word];
      const firstCp = chars[0]?.codePointAt(0) ?? 0;
      const lastTwo = chars.slice(-2).map((c) => c.codePointAt(0)!);

      if (firstCp === 0x0629) {
        findings.push({
          code: 'AR001',
          type: 'potentially-reversed-arabic-literal',
          severity: 'medium',
          file,
          line: lineNum,
          column,
          found: word,
          message: 'Potentially reversed Arabic literal',
        });
        continue;
      }

      if (lastTwo.length === 2 && lastTwo[0] === 0x0644 && lastTwo[1] === 0x0627) {
        findings.push({
          code: 'AR001',
          type: 'potentially-reversed-arabic-literal',
          severity: 'low',
          file,
          line: lineNum,
          column,
          found: word,
          message: 'Potentially reversed Arabic literal',
        });
      }
    }
  }

  return findings;
}
