import { describe, it, expect } from 'vitest';
import * as path from 'path';
import * as fs from 'fs';
import { detectReversedInText } from '../src/check_rtl';
import { filterBySeverity, buildJsonOutput } from '../src/utils';
import { Finding } from '../src/types';

const FIXTURES = path.join(__dirname, 'fixtures');

describe('detectReversedInText', () => {
  // Direction contract: found = the suspicious reversed text from the file,
  //                     suggestion = the corrected logical Arabic text.
  // Verified with explicit Unicode escapes to avoid BiDi display ambiguity.
  it('AR001 direction: found=reversed input, suggestion=corrected form (Unicode escapes)', () => {
    // 'ثحب' = ثحب  (reversed "بحث")
    // 'بحث' = بحث  (correct word for "search")
    const findings = detectReversedInText('ثحب', 'test.txt');
    expect(findings).toHaveLength(1);
    expect(findings[0].found).toBe('ثحب'); // ثحب — the suspicious form found in file
    expect(findings[0].suggestion).toBe('بحث'); // بحث — the corrected form
  });

  it('AR001 direction: دمحم found, محمد suggested (Unicode escapes)', () => {
    // 'دمحم' = دمحم  (reversed "محمد")
    // 'محمد' = محمد  (correct "Muhammad")
    const findings = detectReversedInText('دمحم', 'test.txt');
    expect(findings[0].found).toBe('دمحم'); // دمحم — suspicious
    expect(findings[0].suggestion).toBe('محمد'); // محمد — corrected
  });

  it('returns empty array for clean text', () => {
    expect(detectReversedInText('مرحبا بالعالم', 'test.txt')).toEqual([]);
  });

  it('AR001: high-severity known reversal ثحب → بحث', () => {
    const findings = detectReversedInText('ثحب في القاموس', 'test.txt');
    expect(findings).toHaveLength(1);
    expect(findings[0].code).toBe('AR001');
    expect(findings[0].type).toBe('potentially-reversed-arabic-literal');
    expect(findings[0].severity).toBe('high');
    expect(findings[0].found).toBe('ثحب');
    expect(findings[0].suggestion).toBe('بحث');
    expect(findings[0].line).toBe(1);
    expect(findings[0].column).toBe(1);
  });

  it('AR001: high-severity known reversal دمحم → محمد', () => {
    const findings = detectReversedInText('اسمه دمحم', 'test.txt');
    expect(findings[0].code).toBe('AR001');
    expect(findings[0].severity).toBe('high');
    expect(findings[0].found).toBe('دمحم');
    expect(findings[0].suggestion).toBe('محمد');
  });

  it('AR001: high-severity known reversal تادادعإ → إعدادات', () => {
    const findings = detectReversedInText('تادادعإ النظام', 'test.txt');
    expect(findings[0].code).toBe('AR001');
    expect(findings[0].severity).toBe('high');
    expect(findings[0].suggestion).toBe('إعدادات');
  });

  it('AR001: high-severity known reversal فلم → ملف', () => {
    const findings = detectReversedInText('افتح فلم', 'test.txt');
    expect(findings[0].code).toBe('AR001');
    expect(findings[0].severity).toBe('high');
  });

  it('AR001: high-severity known reversal ظفح → حفظ', () => {
    const findings = detectReversedInText('ظفح الملف', 'test.txt');
    expect(findings[0].code).toBe('AR001');
    expect(findings[0].severity).toBe('high');
  });

  it('AR001: medium-severity heuristic — word starts with ة', () => {
    const findings = detectReversedInText('ةسردم', 'test.txt');
    expect(findings[0].code).toBe('AR001');
    expect(findings[0].severity).toBe('medium');
    expect(findings[0].message).toBe('Potentially reversed Arabic literal');
  });

  it('AR001: low-severity heuristic — word ends with لا', () => {
    const findings = detectReversedInText('هذا مثاللا', 'test.txt');
    const low = findings.filter((f) => f.severity === 'low');
    expect(low.length).toBeGreaterThanOrEqual(1);
    expect(low[0].message).toBe('Potentially reversed Arabic literal');
  });

  it('reports correct line number for multiline text', () => {
    const text = 'مرحبا\nثحب النتائج\nكلمة عادية';
    const findings = detectReversedInText(text, 'test.txt');
    expect(findings[0].line).toBe(2);
  });

  it('reports correct column number', () => {
    const findings = detectReversedInText('نص ثحب', 'test.txt');
    expect(findings[0].column).toBe(4);
  });

  it('ignores non-Arabic words', () => {
    expect(detectReversedInText('hello world 123', 'test.txt')).toEqual([]);
  });

  it('handles empty string', () => {
    expect(detectReversedInText('', 'test.txt')).toEqual([]);
  });

  it('handles multiple findings on the same line', () => {
    const findings = detectReversedInText('ثحب دمحم في المكتبة', 'test.txt');
    const words = findings.map((f) => f.found);
    expect(words).toContain('ثحب');
    expect(words).toContain('دمحم');
  });
});

describe('filterBySeverity', () => {
  const sample: Finding[] = [
    { code: 'AR001', type: 'potentially-reversed-arabic-literal', severity: 'high', file: 'f.txt', line: 1, found: 'x', message: 'm' },
    { code: 'AR001', type: 'potentially-reversed-arabic-literal', severity: 'medium', file: 'f.txt', line: 2, found: 'y', message: 'm' },
    { code: 'AR001', type: 'potentially-reversed-arabic-literal', severity: 'low', file: 'f.txt', line: 3, found: 'z', message: 'm' },
  ];

  it('threshold low returns all findings', () => {
    expect(filterBySeverity(sample, 'low')).toHaveLength(3);
  });

  it('threshold medium filters out low findings', () => {
    const result = filterBySeverity(sample, 'medium');
    expect(result).toHaveLength(2);
    expect(result.every((f) => f.severity !== 'low')).toBe(true);
  });

  it('threshold high returns only high findings', () => {
    const result = filterBySeverity(sample, 'high');
    expect(result).toHaveLength(1);
    expect(result[0].severity).toBe('high');
  });
});

describe('buildJsonOutput', () => {
  it('produces correct JSON shape with tool and command fields', () => {
    const findings = detectReversedInText('ثحب', 'test.txt');
    const output = buildJsonOutput('check-rtl', findings);
    expect(output.tool).toBe('arabic-devtools');
    expect(output.command).toBe('check-rtl');
    expect(Array.isArray(output.findings)).toBe(true);
  });

  it('round-trips through JSON.stringify without data loss', () => {
    const findings = detectReversedInText('ثحب', 'test.txt');
    const output = buildJsonOutput('check-rtl', findings);
    const parsed = JSON.parse(JSON.stringify(output));
    expect(parsed.findings[0].code).toBe('AR001');
    expect(parsed.findings[0].severity).toBe('high');
    expect(parsed.findings[0].found).toBe('ثحب');
    expect(parsed.findings[0].suggestion).toBe('بحث');
  });
});

describe('fixtures', () => {
  it('reversed_literals.txt produces AR001 findings only', () => {
    const content = fs.readFileSync(path.join(FIXTURES, 'reversed_literals.txt'), 'utf-8');
    const findings = detectReversedInText(content, 'reversed_literals.txt');
    expect(findings.length).toBeGreaterThan(0);
    expect(findings.every((f) => f.code === 'AR001')).toBe(true);
  });

  it('clean_arabic.txt produces no findings', () => {
    const content = fs.readFileSync(path.join(FIXTURES, 'clean_arabic.txt'), 'utf-8');
    const findings = detectReversedInText(content, 'clean_arabic.txt');
    expect(findings).toHaveLength(0);
  });
});
