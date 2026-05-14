#!/usr/bin/env node
import { detectReversedInText } from './check_rtl';
import { scanPath } from './scan';
import { runBidi } from './bidi';

const [, , command, ...args] = process.argv;

function printUsage(): void {
  console.log('arabic-devtools — CLI for Arabic text development');
  console.log('');
  console.log('Commands:');
  console.log('  check-rtl <path>   Detect potentially reversed Arabic literals');
  console.log('  scan <path>        Scan for tatweel, tashkeel, mixed digits, and reversed RTL');
  console.log('  bidi "<text>"      Prepare Arabic text for terminal output (BiDi)');
}

if (command === 'check-rtl') {
  const target = args[0];
  if (!target) {
    console.error('Error: path required');
    process.exit(2);
  }
  const fs = require('fs') as typeof import('fs');
  const content = fs.readFileSync(target, 'utf-8');
  const findings = detectReversedInText(content);
  if (findings.length === 0) {
    console.log('لا توجد مشاكل.');
    process.exit(0);
  }
  for (const f of findings) {
    console.log(`[${f.confidence.toUpperCase()}] سطر ${f.line}: "${f.word}" — ${f.reason}`);
  }
  process.exit(1);
} else if (command === 'scan') {
  const target = args[0];
  if (!target) {
    console.error('Error: path required');
    process.exit(2);
  }
  const issues = scanPath(target);
  if (issues.length === 0) {
    console.log('لا توجد مشاكل.');
    process.exit(0);
  }
  for (const issue of issues) {
    const conf = issue.confidence ? ` [${issue.confidence.toUpperCase()}]` : '';
    console.log(`${issue.file}:${issue.line} [${issue.type}]${conf} — ${issue.detail}`);
  }
  process.exit(1);
} else if (command === 'bidi') {
  const text = args[0];
  if (text === undefined) {
    console.error('Error: text argument required');
    process.exit(2);
  }
  runBidi(text);
  process.exit(0);
} else {
  printUsage();
  process.exit(command ? 2 : 0);
}
