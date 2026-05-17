import { prepareForTerminal } from '@devsamhan/arabic-bidi';

export type BidiMode = 'full' | 'reshape-only' | 'no-reshape';

export function runBidi(text: string, mode: BidiMode = 'full'): void {
  let output: string;
  if (mode === 'reshape-only') {
    output = prepareForTerminal(text, { reshape: true, reorder: false });
  } else if (mode === 'no-reshape') {
    output = prepareForTerminal(text, { reshape: false, reorder: true });
  } else {
    output = prepareForTerminal(text);
  }
  process.stdout.write(output + '\n');
}
