import { Finding } from './types';

const KNOWN_REVERSALS: Record<string, string> = {
  ثحب: 'بحث',
  دمحم: 'محمد',
  تادادعإ: 'إعدادات',
  فلم: 'ملف',
  ظفح: 'حفظ',
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
    const wordRegex = /\S+/g;
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
