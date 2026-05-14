import { Finding, JsonOutput, Severity } from './types';

export const SEVERITY_ORDER: Record<Severity, number> = { low: 0, medium: 1, high: 2 };

export function filterBySeverity(findings: Finding[], threshold: Severity): Finding[] {
  return findings.filter((f) => SEVERITY_ORDER[f.severity] >= SEVERITY_ORDER[threshold]);
}

export function buildJsonOutput(command: string, findings: Finding[]): JsonOutput {
  return { tool: 'arabic-devtools', command, findings };
}

export function formatText(findings: Finding[]): string {
  return findings
    .map((f) => {
      const col = f.column !== undefined ? `:${f.column}` : '';
      const sugg = f.suggestion ? ` → ${f.suggestion}` : '';
      return `${f.file}:${f.line}${col} [${f.code}/${f.severity}] "${f.found}"${sugg} — ${f.message}`;
    })
    .join('\n');
}
