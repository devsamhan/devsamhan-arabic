import * as fs from 'fs';
import * as path from 'path';
import { detectReversedInText } from './check_rtl';
import { Finding } from './types';

const TATWEEL = 0x0640;
const TASHKEEL_START = 0x064b;
const TASHKEEL_END = 0x065f;

function findColumn(line: string, predicate: (cp: number) => boolean): number | undefined {
  const chars = [...line];
  for (let i = 0; i < chars.length; i++) {
    if (predicate(chars[i].codePointAt(0)!)) return i + 1;
  }
  return undefined;
}

export function detectIssuesInText(content: string, filePath: string): Finding[] {
  const findings: Finding[] = [];
  const lines = content.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const lineNum = i + 1;

    const tatweelCol = findColumn(line, (cp) => cp === TATWEEL);
    if (tatweelCol !== undefined) {
      findings.push({
        code: 'AR002',
        type: 'excessive-tatweel',
        severity: 'medium',
        file: filePath,
        line: lineNum,
        column: tatweelCol,
        found: 'ـ',
        message: 'Tatweel (kashida) found — avoid in digital text',
      });
    }

    const tashkeelCol = findColumn(line, (cp) => cp >= TASHKEEL_START && cp <= TASHKEEL_END);
    if (tashkeelCol !== undefined) {
      const tashkeelChar = [...line].find((c) => {
        const cp = c.codePointAt(0)!;
        return cp >= TASHKEEL_START && cp <= TASHKEEL_END;
      })!;
      findings.push({
        code: 'AR003',
        type: 'tashkeel-in-search-key',
        severity: 'medium',
        file: filePath,
        line: lineNum,
        column: tashkeelCol,
        found: tashkeelChar,
        message: 'Tashkeel (diacritics) found — strip before use in search keys',
      });
    }

    const hasEastern = [...line].some((c) => {
      const cp = c.codePointAt(0)!;
      return cp >= 0x0660 && cp <= 0x0669;
    });
    const hasWestern = /[0-9]/.test(line);
    if (hasEastern && hasWestern) {
      const col = findColumn(line, (cp) => (cp >= 0x0660 && cp <= 0x0669) || (cp >= 0x0030 && cp <= 0x0039));
      const firstEastern = [...line].find((c) => {
        const cp = c.codePointAt(0)!;
        return cp >= 0x0660 && cp <= 0x0669;
      })!;
      findings.push({
        code: 'AR004',
        type: 'mixed-digit-scripts',
        severity: 'low',
        file: filePath,
        line: lineNum,
        column: col,
        found: firstEastern,
        message: 'Mixed Eastern Arabic and Western digit scripts on the same line',
      });
    }
  }

  findings.push(...detectReversedInText(content, filePath));
  findings.sort((a, b) => a.line - b.line);
  return findings;
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

export function scanPath(targetPath: string): Finding[] {
  const files = collectFiles(targetPath);
  const all: Finding[] = [];
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
