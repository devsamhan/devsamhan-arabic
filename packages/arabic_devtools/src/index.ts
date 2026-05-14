#!/usr/bin/env node
import * as fs from 'fs';
import { detectReversedInText } from './check_rtl';
import { scanPath } from './scan';
import { runBidi } from './bidi';
import { filterBySeverity, buildJsonOutput, formatText } from './utils';
import { Severity, OutputFormat } from './types';

const [, , command, ...rawArgs] = process.argv;

interface ParsedArgs {
  path: string;
  format: OutputFormat;
  threshold: Severity;
}

function parseArgs(args: string[]): ParsedArgs {
  let target = '';
  let format: OutputFormat = 'text';
  let threshold: Severity = 'low';

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--format' && i + 1 < args.length) {
      const val = args[++i];
      if (val === 'text' || val === 'json') format = val;
    } else if (args[i] === '--severity-threshold' && i + 1 < args.length) {
      const val = args[++i];
      if (val === 'low' || val === 'medium' || val === 'high') threshold = val as Severity;
    } else if (!args[i].startsWith('--')) {
      target = args[i];
    }
  }

  return { path: target, format, threshold };
}

function printUsage(): void {
  console.log('arabic-devtools — CLI for Arabic text development');
  console.log('');
  console.log('Commands:');
  console.log('  check-rtl <path> [--format text|json] [--severity-threshold low|medium|high]');
  console.log('  scan <path> [--format text|json] [--severity-threshold low|medium|high]');
  console.log('  bidi "<text>"');
}

if (command === 'check-rtl') {
  const { path: target, format, threshold } = parseArgs(rawArgs);
  if (!target) {
    console.error('Error: path required');
    process.exit(2);
  }
  const content = fs.readFileSync(target, 'utf-8');
  const all = detectReversedInText(content, target);
  const findings = filterBySeverity(all, threshold);

  if (format === 'json') {
    console.log(JSON.stringify(buildJsonOutput('check-rtl', findings), null, 2));
  } else {
    if (findings.length === 0) {
      console.log('لا توجد مشاكل.');
    } else {
      console.log(formatText(findings));
    }
  }
  process.exit(findings.length > 0 ? 1 : 0);
} else if (command === 'scan') {
  const { path: target, format, threshold } = parseArgs(rawArgs);
  if (!target) {
    console.error('Error: path required');
    process.exit(2);
  }
  const all = scanPath(target);
  const findings = filterBySeverity(all, threshold);

  if (format === 'json') {
    console.log(JSON.stringify(buildJsonOutput('scan', findings), null, 2));
  } else {
    if (findings.length === 0) {
      console.log('لا توجد مشاكل.');
    } else {
      console.log(formatText(findings));
    }
  }
  process.exit(findings.length > 0 ? 1 : 0);
} else if (command === 'bidi') {
  const text = rawArgs[0];
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
