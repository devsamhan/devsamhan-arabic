import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import * as path from 'path';
import * as os from 'os';
import * as fs from 'fs';
import { detectReversedInText } from '../src/check_rtl';
import { filterBySeverity, buildJsonOutput } from '../src/utils';
import { Finding } from '../src/types';

const FIXTURES = path.join(__dirname, 'fixtures');

describe('AR001 Unicode contract', () => {
  // All string literals here use explicit \uXXXX escapes so the direction
  // cannot be misread by any editor, terminal, or BiDi renderer.
  const REVERSED_SEARCH   = 'ثحب'; // ثحب — reversed form of بحث "search"
  const CORRECT_SEARCH    = 'بحث'; // بحث — correct form
  const REVERSED_MUHAMMAD = 'دمحم'; // دمحم — reversed form of محمد "Muhammad"
  const CORRECT_MUHAMMAD  = 'محمد'; // محمد — correct form

  it('U+062B U+062D U+0628 (ثحب): found=reversed, suggestion=correct, severity=high', () => {
    const findings = detectReversedInText(REVERSED_SEARCH, 'test.txt');
    expect(findings).toHaveLength(1);
    expect(findings[0].code).toBe('AR001');
    expect(findings[0].severity).toBe('high');
    expect(findings[0].found).toBe(REVERSED_SEARCH);
    expect(findings[0].suggestion).toBe(CORRECT_SEARCH);
  });

  it('U+062F U+0645 U+062D U+0645 (دمحم): found=reversed, suggestion=correct, severity=high', () => {
    const findings = detectReversedInText(REVERSED_MUHAMMAD, 'test.txt');
    expect(findings).toHaveLength(1);
    expect(findings[0].code).toBe('AR001');
    expect(findings[0].severity).toBe('high');
    expect(findings[0].found).toBe(REVERSED_MUHAMMAD);
    expect(findings[0].suggestion).toBe(CORRECT_MUHAMMAD);
  });

  it('correct form U+0628 U+062D U+062B (بحث) is not flagged', () => {
    expect(detectReversedInText(CORRECT_SEARCH, 'test.txt')).toHaveLength(0);
  });

  it('correct form U+0645 U+062D U+0645 U+062F (محمد) is not flagged', () => {
    expect(detectReversedInText(CORRECT_MUHAMMAD, 'test.txt')).toHaveLength(0);
  });

  it('unicode_reversed.txt fixture: detects both reversed words', () => {
    const content = fs.readFileSync(path.join(FIXTURES, 'unicode_reversed.txt'), 'utf-8');
    const findings = detectReversedInText(content, 'unicode_reversed.txt');
    expect(findings).toHaveLength(2);
    const found = findings.map((f) => f.found);
    expect(found).toContain(REVERSED_SEARCH);
    expect(found).toContain(REVERSED_MUHAMMAD);
  });
});

describe('detectReversedInText', () => {
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

describe('integration: temp file with explicit Unicode escapes (code-like content)', () => {
  // All strings use raw \uXXXX escapes — zero BiDi ambiguity at the source level.
  const WRONG_SEARCH   = 'ثحب'; // ثحب  reversed "search"
  const WRONG_MUHAMMAD = 'دمحم'; // دمحم  reversed "Muhammad"
  const OK_SEARCH      = 'بحث'; // بحث  correct "search"
  const OK_MUHAMMAD    = 'محمد'; // محمد  correct "Muhammad"

  // Simulate the exact Dart/JS file that triggered the real-world bug report:
  // Arabic appears inside single-quoted string literals, not as bare words.
  const CODE_CONTENT = [
    `const wrongHint = '${WRONG_SEARCH}';`,
    `const wrongName = '${WRONG_MUHAMMAD}';`,
    `const okHint = '${OK_SEARCH}';`,
    `const okName = '${OK_MUHAMMAD}';`,
  ].join('\n');

  const tmpFile = path.join(os.tmpdir(), `arabic-devtools-integration-${Date.now()}.dart`);
  let findings: ReturnType<typeof detectReversedInText>;

  beforeAll(() => {
    fs.writeFileSync(tmpFile, CODE_CONTENT, 'utf-8');
    const read = fs.readFileSync(tmpFile, 'utf-8');
    findings = detectReversedInText(read, tmpFile);
  });

  afterAll(() => {
    try { fs.unlinkSync(tmpFile); } catch { /* ignore */ }
  });

  it('produces exactly 2 findings for code file with 2 reversed + 2 correct Arabic literals', () => {
    expect(findings).toHaveLength(2);
  });

  it('detects reversed search form inside string literal (U+062B U+062D U+0628)', () => {
    expect(findings.map((f) => f.found)).toContain(WRONG_SEARCH);
  });

  it('detects reversed Muhammad form inside string literal (U+062F U+0645 U+062D U+0645)', () => {
    expect(findings.map((f) => f.found)).toContain(WRONG_MUHAMMAD);
  });

  it('does not flag correct search form (U+0628 U+062D U+062B)', () => {
    expect(findings.map((f) => f.found)).not.toContain(OK_SEARCH);
  });

  it('does not flag correct Muhammad form (U+0645 U+062D U+0645 U+062F)', () => {
    expect(findings.map((f) => f.found)).not.toContain(OK_MUHAMMAD);
  });

  it('found fields contain only Arabic characters — no surrounding punctuation', () => {
    for (const f of findings) {
      const cps = [...f.found].map((c) => c.codePointAt(0)!);
      expect(cps.every((cp) => cp >= 0x0600 && cp <= 0x06ff)).toBe(true);
    }
  });
});
