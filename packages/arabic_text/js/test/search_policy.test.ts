import { describe, it, expect } from 'vitest';
import {
  normalizeTaMarbouta,
  toLooseSearchKey,
  toSearchKey,
} from '../src/index';

// AR-001: strict index must only be queried with a strict query; loose index
// must only be queried with a loose query. The cross-mode case is a deliberate
// false-negative regression assertion, not a supported pattern.
const STORED = 'فاطمة العلي';
const QUERY_TA = 'فاطمة';
const QUERY_HA = 'فاطمه';

describe('search matching policy', () => {
  it('strict/strict matches the same spelling', () => {
    expect(toSearchKey(STORED).includes(toSearchKey(QUERY_TA))).toBe(true);
  });

  it('loose/loose matches both ta marbouta spellings', () => {
    const looseStored = toLooseSearchKey(STORED);
    expect(looseStored.includes(toLooseSearchKey(QUERY_TA))).toBe(true);
    expect(looseStored.includes(toLooseSearchKey(QUERY_HA))).toBe(true);
  });

  it('strict/loose produces the documented false negative', () => {
    const strictStored = toSearchKey(STORED);
    expect(strictStored.includes(toLooseSearchKey(QUERY_TA))).toBe(false);
    expect(strictStored.includes(toLooseSearchKey(QUERY_HA))).toBe(false);
  });

  it('loose stored key is derived by ta-marbouta normalization of strict key', () => {
    expect(normalizeTaMarbouta(toSearchKey(STORED))).toBe(
      toLooseSearchKey(STORED)
    );
  });

  it('conservative strict key still preserves ta marbouta', () => {
    expect(toSearchKey(STORED)).toBe(STORED);
    expect(toSearchKey(QUERY_HA)).toBe(QUERY_HA);
  });
});
