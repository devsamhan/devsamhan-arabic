import * as fs from 'fs';
import * as path from 'path';
import { detectReversedInText, RtlFinding } from './check_rtl';

export interface ScanIssue {
  file: string;
  line: number;
  type: 'tatweel' | 'tashkeel' | 'mixed-digits' | 'reversed-rtl';
  detail: string;
  confidence?: 'high' | 'medium' | 'low';
}

const TATWEEL = 0x0640;
const TASHKEEL_RANGE: [number, number] = [0x064b, 0x065f];

function hasTatweel(text: string): boolean {
  return [...text].some((c) => c.codePointAt(0) === TATWEEL);
}

function hasTashkeel(text: string): boolean {
  return [...text].some((c) => {
    const cp = c.codePointAt(0)!;
    return cp >= TASHKEEL_RANGE[0] && cp <= TASHKEEL_RANGE[1];
  });
}

function hasMixedDigits(text: string): boolean {
  const hasEastern = [...text].some((c) => {
    const cp = c.codePointAt(0)!;
    return cp >= 0x0660 && cp <= 0x0669;
  });
  const hasWestern = /[0-9]/.test(text);
  return hasEastern && hasWestern;
}

export function detectIssuesInText(content: string, filePath: string): ScanIssue[] {
  const issues: ScanIssue[] = [];
  const lines = content.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const lineNum = i + 1;

    if (hasTatweel(line)) {
      issues.push({ file: filePath, line: lineNum, type: 'tatweel', detail: 'تطويل (ـ) في السطر' });
    }
    if (hasTashkeel(line)) {
      issues.push({ file: filePath, line: lineNum, type: 'tashkeel', detail: 'تشكيل في السطر' });
    }
    if (hasMixedDigits(line)) {
      issues.push({ file: filePath, line: lineNum, type: 'mixed-digits', detail: 'خلط أرقام عربية وغربية في السطر' });
    }
  }

  const rtlFindings: RtlFinding[] = detectReversedInText(content);
  for (const f of rtlFindings) {
    issues.push({
      file: filePath,
      line: f.line,
      type: 'reversed-rtl',
      detail: `"${f.word}" — ${f.reason}`,
      confidence: f.confidence,
    });
  }

  return issues;
}

function collectFiles(target: string): string[] {
  const stat = fs.statSync(target);
  if (stat.isFile()) return [target];
  const results: string[] = [];
  for (const entry of fs.readdirSync(target)) {
    const full = path.join(target, entry);
    results.push(...collectFiles(full));
  }
  return results;
}

export function scanPath(targetPath: string): ScanIssue[] {
  const files = collectFiles(targetPath);
  const all: ScanIssue[] = [];
  for (const file of files) {
    try {
      const content = fs.readFileSync(file, 'utf-8');
      all.push(...detectIssuesInText(content, file));
    } catch {
      // skip unreadable files
    }
  }
  return all;
}
