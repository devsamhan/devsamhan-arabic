export type RuleCode = 'AR001' | 'AR002' | 'AR003' | 'AR004';
export type Severity = 'low' | 'medium' | 'high';
export type OutputFormat = 'text' | 'json';

export interface Finding {
  code: RuleCode;
  type: string;
  severity: Severity;
  file: string;
  line: number;
  column?: number;
  found: string;
  suggestion?: string;
  message: string;
}

export interface JsonOutput {
  tool: 'arabic-devtools';
  command: string;
  findings: Finding[];
}
