#!/usr/bin/env node
import * as fs from 'fs';
import { detectReversedInText } from './check_rtl';
import { scanPath } from './scan';
import { runBidi, BidiMode } from './bidi';
import { filterBySeverity, buildJsonOutput, formatText } from './utils';
import { Severity, OutputFormat, Finding } from './types';

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

function readFileOrExit(filePath: string): string {
  try {
    return fs.readFileSync(filePath, 'utf-8');
  } catch (err: unknown) {
    if ((err as NodeJS.ErrnoException).code === 'ENOENT') {
      console.error(`Path not found: ${filePath}`);
      process.exit(1);
    }
    throw err;
  }
}

function scanOrExit(targetPath: string): Finding[] {
  try {
    return scanPath(targetPath);
  } catch (err: unknown) {
    const code = (err as NodeJS.ErrnoException).code;
    if (code === 'PATH_NOT_FOUND' || code === 'ENOENT') {
      console.error(`Path not found: ${targetPath}`);
      process.exit(1);
    }
    throw err;
  }
}

function printUsage(): void {
  console.log('arabic-devtools — CLI for Arabic text development');
  console.log('');
  console.log('Commands:');
  console.log('  check-rtl <path> [--format text|json] [--severity-threshold low|medium|high]');
  console.log('  scan <path> [--format text|json] [--severity-threshold low|medium|high]');
  console.log('  bidi "<text>" [--reshape-only | --no-reorder | --no-reshape]');
  console.log('');
  console.log('bidi flags:');
  console.log('  (default)       reshape + reorder — for terminals that do not handle Arabic');
  console.log('  --reshape-only  connect Arabic letters; no run reorder');
  console.log('  --no-reorder    same as --reshape-only');
  console.log('  --no-reshape    reorder only; no letter reshaping');
  console.log('');
  console.log('Note: modern terminals (Windows Terminal, iTerm2) may already render Arabic');
  console.log('correctly. Use bidi only if output looks wrong in your environment.');
}

if (command === 'check-rtl') {
  const { path: target, format, threshold } = parseArgs(rawArgs);
  if (!target) {
    console.error('Error: path required');
    process.exit(2);
  }
  const content = readFileOrExit(target);
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
  const all = scanOrExit(target);
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
  const text = rawArgs.find((a) => !a.startsWith('--'));
  if (text === undefined) {
    console.error('Error: text argument required');
    process.exit(2);
  }
  let mode: BidiMode = 'full';
  if (rawArgs.includes('--reshape-only') || rawArgs.includes('--no-reorder')) {
    mode = 'reshape-only';
  } else if (rawArgs.includes('--no-reshape')) {
    mode = 'no-reshape';
  }
  runBidi(text, mode);
  process.exit(0);
} else {
  printUsage();
  process.exit(command ? 2 : 0);
}
