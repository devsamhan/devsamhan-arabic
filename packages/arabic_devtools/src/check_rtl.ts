export interface RtlFinding {
  line: number;
  word: string;
  confidence: 'high' | 'medium' | 'low';
  reason: string;
}

const KNOWN_REVERSALS: Record<string, string> = {
  ثحب: 'بحث',
  دمحم: 'محمد',
  تادادعإ: 'إعدادات',
  فلم: 'ملف',
  ظفح: 'حفظ',
};

function isArabicChar(cp: number): boolean {
  return (cp >= 0x0621 && cp <= 0x063A) || (cp >= 0x0641 && cp <= 0x064A);
}

function isArabicWord(word: string): boolean {
  const chars = [...word];
  if (chars.length === 0) return false;
  return chars.some((c) => isArabicChar(c.codePointAt(0)!));
}

export function detectReversedInText(text: string): RtlFinding[] {
  const findings: RtlFinding[] = [];
  const lines = text.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const lineNum = i + 1;
    const words = lines[i].split(/\s+/).filter((w) => w.length > 0);

    for (const word of words) {
      if (!isArabicWord(word)) continue;

      if (KNOWN_REVERSALS[word] !== undefined) {
        findings.push({
          line: lineNum,
          word,
          confidence: 'high',
          reason: `كلمة معكوسة معروفة — الصحيح: ${KNOWN_REVERSALS[word]}`,
        });
        continue;
      }

      const chars = [...word];
      const firstCp = chars[0]?.codePointAt(0) ?? 0;
      const lastTwo = chars.slice(-2).map((c) => c.codePointAt(0)!);

      if (firstCp === 0x0629) {
        findings.push({
          line: lineNum,
          word,
          confidence: 'medium',
          reason: 'الكلمة تبدأ بتاء مربوطة (ة) — قد تكون معكوسة',
        });
        continue;
      }

      if (lastTwo.length === 2 && lastTwo[0] === 0x0644 && lastTwo[1] === 0x0627) {
        findings.push({
          line: lineNum,
          word,
          confidence: 'low',
          reason: 'الكلمة تنتهي بـ لا — قد تكون معكوسة',
        });
      }
    }
  }

  return findings;
}
