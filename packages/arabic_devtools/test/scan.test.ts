import { describe, it, expect } from 'vitest';
import * as path from 'path';
import * as fs from 'fs';
import { detectIssuesInText, scanPath } from '../src/scan';
import { runBidi } from '../src/bidi';

const FIXTURES = path.join(__dirname, 'fixtures');

describe('detectIssuesInText', () => {
  it('AR002: detects tatweel with correct code and severity', () => {
    const findings = detectIssuesInText('هذاـ نص', 'test.txt');
    const ar002 = findings.filter((f) => f.code === 'AR002');
    expect(ar002.length).toBeGreaterThan(0);
    expect(ar002[0].found).toBe('ـ');
    expect(ar002[0].severity).toBe('medium');
    expect(ar002[0].type).toBe('excessive-tatweel');
  });

  it('AR002: reports correct column for tatweel', () => {
    const findings = detectIssuesInText('نص ـ كلام', 'test.txt');
    const ar002 = findings.filter((f) => f.code === 'AR002');
    expect(ar002[0].column).toBe(4);
  });

  it('AR003: detects tashkeel with correct code and severity', () => {
    const findings = detectIssuesInText('نَصٌّ', 'test.txt');
    const ar003 = findings.filter((f) => f.code === 'AR003');
    expect(ar003.length).toBeGreaterThan(0);
    expect(ar003[0].severity).toBe('medium');
    expect(ar003[0].type).toBe('tashkeel-in-search-key');
  });

  it('AR004: detects mixed Eastern + Western digits', () => {
    const findings = detectIssuesInText('المبلغ 100 و١٢٣', 'test.txt');
    const ar004 = findings.filter((f) => f.code === 'AR004');
    expect(ar004.length).toBeGreaterThan(0);
    expect(ar004[0].severity).toBe('low');
    expect(ar004[0].type).toBe('mixed-digit-scripts');
  });

  it('AR004: does not fire when only Eastern digits present', () => {
    const findings = detectIssuesInText('المبلغ ١٢٣ ريال', 'test.txt');
    expect(findings.filter((f) => f.code === 'AR004')).toHaveLength(0);
  });

  it('AR004: does not fire when only Western digits present', () => {
    const findings = detectIssuesInText('price 123 dollars', 'test.txt');
    expect(findings.filter((f) => f.code === 'AR004')).toHaveLength(0);
  });

  it('clean Arabic text produces no findings', () => {
    expect(detectIssuesInText('مرحبا بالعالم', 'test.txt')).toHaveLength(0);
  });

  it('Latin-only text produces no findings', () => {
    expect(detectIssuesInText('hello world 123', 'test.txt')).toHaveLength(0);
  });

  it('findings are sorted by line number', () => {
    const text = 'المبلغ 100 و١٢٣\nنَصٌّ';
    const findings = detectIssuesInText(text, 'test.txt');
    for (let i = 1; i < findings.length; i++) {
      expect(findings[i].line).toBeGreaterThanOrEqual(findings[i - 1].line);
    }
  });
});

describe('scan fixtures', () => {
  it('scan_issues.txt produces AR002, AR003, and AR004 findings', () => {
    const content = fs.readFileSync(path.join(FIXTURES, 'scan_issues.txt'), 'utf-8');
    const findings = detectIssuesInText(content, 'scan_issues.txt');
    const codes = new Set(findings.map((f) => f.code));
    expect(codes.has('AR002')).toBe(true);
    expect(codes.has('AR003')).toBe(true);
    expect(codes.has('AR004')).toBe(true);
  });

  it('clean_mixed.txt produces no findings', () => {
    const content = fs.readFileSync(path.join(FIXTURES, 'clean_mixed.txt'), 'utf-8');
    const findings = detectIssuesInText(content, 'clean_mixed.txt');
    expect(findings).toHaveLength(0);
  });
});

describe('scanPath error handling', () => {
  it('throws with code PATH_NOT_FOUND for non-existent path', () => {
    expect(() => scanPath('/nonexistent/path/that/does/not/exist')).toThrow();
    try {
      scanPath('/nonexistent/path/that/does/not/exist');
    } catch (err: unknown) {
      expect((err as NodeJS.ErrnoException).code).toBe('PATH_NOT_FOUND');
      expect((err as Error).message).toContain('Path not found');
    }
  });
});

describe('bidi modes', () => {
  const arabicText = 'مرحبا';
  // Multi-word Arabic: reorder swaps word order; reshape-only preserves it.
  const multiWordArabic = 'مرحبا بالعالم';

  function capture(fn: () => void): string {
    let out = '';
    const orig = process.stdout.write.bind(process.stdout);
    (process.stdout as any).write = (s: string) => { out += s; return true; };
    fn();
    (process.stdout as any).write = orig;
    return out;
  }

  it('full mode (default) returns a string', () => {
    const output = capture(() => runBidi(arabicText, 'full'));
    expect(typeof output).toBe('string');
    expect(output.length).toBeGreaterThan(0);
  });

  it('reshape-only produces different output from full for multi-word RTL text', () => {
    const fullOut    = capture(() => runBidi(multiWordArabic, 'full'));
    const reshapeOut = capture(() => runBidi(multiWordArabic, 'reshape-only'));
    // full reorders word runs; reshape-only keeps original word order
    expect(fullOut).not.toBe(reshapeOut);
  });

  it('no-reshape mode returns a string', () => {
    const output = capture(() => runBidi(arabicText, 'no-reshape'));
    expect(typeof output).toBe('string');
    expect(output.length).toBeGreaterThan(0);
  });
});
