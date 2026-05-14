import { prepareForTerminal } from '@devsamhan/arabic-bidi';

export function runBidi(text: string): void {
  process.stdout.write(prepareForTerminal(text) + '\n');
}
