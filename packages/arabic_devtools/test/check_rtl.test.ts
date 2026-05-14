import { describe, it, expect } from 'vitest';
import { detectReversedInText } from '../src/check_rtl';

describe('detectReversedInText', () => {
  it('returns empty array for clean text', () => {
    expect(detectReversedInText('مرحبا بالعالم')).toEqual([]);
  });

  it('detects high-confidence known reversal: ثحب → بحث', () => {
    const findings = detectReversedInText('ثحب في القاموس');
    expect(findings).toHaveLength(1);
    expect(findings[0].word).toBe('ثحب');
    expect(findings[0].confidence).toBe('high');
    expect(findings[0].line).toBe(1);
    expect(findings[0].reason).toContain('بحث');
  });

  it('detects high-confidence known reversal: دمحم → محمد', () => {
    const findings = detectReversedInText('اسمه دمحم');
    expect(findings).toHaveLength(1);
    expect(findings[0].word).toBe('دمحم');
    expect(findings[0].confidence).toBe('high');
  });

  it('detects high-confidence known reversal: تادادعإ → إعدادات', () => {
    const findings = detectReversedInText('تادادعإ النظام');
    expect(findings[0].confidence).toBe('high');
    expect(findings[0].word).toBe('تادادعإ');
  });

  it('detects high-confidence known reversal: فلم → ملف', () => {
    const findings = detectReversedInText('فتح فلم');
    expect(findings[0].confidence).toBe('high');
    expect(findings[0].word).toBe('فلم');
  });

  it('detects high-confidence known reversal: ظفح → حفظ', () => {
    const findings = detectReversedInText('ظفح الملف');
    expect(findings[0].confidence).toBe('high');
    expect(findings[0].word).toBe('ظفح');
  });

  it('detects medium-confidence word starting with ة', () => {
    const findings = detectReversedInText('ةسردم');
    expect(findings).toHaveLength(1);
    expect(findings[0].confidence).toBe('medium');
    expect(findings[0].word).toBe('ةسردم');
  });

  it('detects low-confidence word ending with لا', () => {
    const findings = detectReversedInText('هذا مثاللا');
    const low = findings.filter((f) => f.confidence === 'low');
    expect(low.length).toBeGreaterThanOrEqual(1);
    expect(low[0].word).toBe('مثاللا');
  });

  it('reports correct line numbers for multiline text', () => {
    const text = 'مرحبا\nثحب النتائج\nكلمة عادية';
    const findings = detectReversedInText(text);
    expect(findings[0].line).toBe(2);
  });

  it('ignores non-Arabic words', () => {
    expect(detectReversedInText('hello world 123')).toEqual([]);
  });

  it('handles empty string', () => {
    expect(detectReversedInText('')).toEqual([]);
  });

  it('handles multiple findings on the same line', () => {
    const findings = detectReversedInText('ثحب دمحم في المكتبة');
    const words = findings.map((f) => f.word);
    expect(words).toContain('ثحب');
    expect(words).toContain('دمحم');
  });
});
