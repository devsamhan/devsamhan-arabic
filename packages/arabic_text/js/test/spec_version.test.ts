import { describe, expect, it } from 'vitest';
import { specVersion } from '../src/index';

describe('SPEC_VERSION regression', () => {
  it('is the 1.0.1 clarification', () => {
    expect(specVersion).toBe('1.0.1');
  });
});
