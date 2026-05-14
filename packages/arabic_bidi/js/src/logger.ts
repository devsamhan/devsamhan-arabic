// Arabic-aware terminal logger — devsamhan-arabic spec v1.0.0
//
// Output format: [timestamp?][prefix?][LEVEL] message

import { prepareForTerminal, TerminalOptions } from './terminal';

export interface ArabicLoggerOptions {
  prefix?: string;
  useTimestamp?: boolean;
  terminalOptions?: TerminalOptions;
}

export class ArabicLogger {
  private readonly prefix: string | undefined;
  private readonly useTimestamp: boolean;
  private readonly terminalOptions: TerminalOptions;

  constructor(options?: ArabicLoggerOptions) {
    this.prefix = options?.prefix;
    this.useTimestamp = options?.useTimestamp ?? false;
    this.terminalOptions = options?.terminalOptions ?? {};
  }

  info(message: string): void  { this._log('INFO',  message); }
  error(message: string): void { this._log('ERROR', message); }
  warn(message: string): void  { this._log('WARN',  message); }
  debug(message: string): void { this._log('DEBUG', message); }

  private _log(level: string, message: string): void {
    const prepared = prepareForTerminal(message, this.terminalOptions);
    let line = '';
    if (this.useTimestamp) {
      const now = new Date();
      const pad = (n: number) => String(n).padStart(2, '0');
      const ts = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;
      line += `[${ts}]`;
    }
    if (this.prefix !== undefined) line += `[${this.prefix}]`;
    line += `[${level}] ${prepared}`;
    console.log(line);
  }
}

export const arabicLogger = new ArabicLogger();
