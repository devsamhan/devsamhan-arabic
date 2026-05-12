import { describe, it, expect } from 'vitest';
import * as path from 'path';
import * as fs from 'fs';
import * as api from '../src/index';

// From packages/arabic_text/js/test/ → up 4 levels → monorepo root → test_fixtures/
const FIXTURES_DIR = path.resolve(__dirname, '..', '..', '..', '..', 'test_fixtures');

interface FixtureCase {
  id: string;
  name?: string;
  operation: string;
  input: string | string[];
  options?: Record<string, string>;
  expected: string | string[] | number | boolean;
}

interface FixtureFile {
  meta: { spec_version: number; description: string };
  cases: FixtureCase[];
}

function runCase(c: FixtureCase): unknown {
  switch (c.operation) {
    case 'removeTashkeel':
      return api.removeTashkeel(c.input as string);
    case 'removeTatweel':
      return api.removeTatweel(c.input as string);
    case 'normalizeAlef':
      return api.normalizeAlef(c.input as string);
    case 'normalizeHamza':
      return api.normalizeHamza(c.input as string);
    case 'normalizeYa':
      return api.normalizeYa(c.input as string);
    case 'normalizeTaMarbouta':
      return api.normalizeTaMarbouta(c.input as string);
    case 'normalizePresentationForms':
      return api.normalizePresentationForms(c.input as string);
    case 'normalizeDigits':
      return api.normalizeDigits(c.input as string, c.options!.to as 'western' | 'eastern');
    case 'toSearchKey':
      return api.toSearchKey(c.input as string);
    case 'toLooseSearchKey':
      return api.toLooseSearchKey(c.input as string);
    case 'toDisplayKey':
      return api.toDisplayKey(c.input as string);
    case 'toSlug':
      return api.toSlug(c.input as string);
    case 'normalizeName':
      return api.normalizeName(c.input as string);
    case 'toSortKey':
      if (Array.isArray(c.input)) return (c.input as string[]).map(api.toSortKey);
      return api.toSortKey(c.input as string);
    case 'sort':
      return api.sort(c.input as string[]);
    case 'compare': {
      const [a, b] = c.input as string[];
      return api.compare(a, b);
    }
    case 'isArabic':
      return api.isArabic(c.input as string);
    case 'arabicRatio':
      return api.arabicRatio(c.input as string);
    default:
      throw new Error(`Unknown operation: ${c.operation}`);
  }
}

const FIXTURE_FILES = [
  'normalize.json',
  'search_key.json',
  'numbers.json',
  'mixed_text.json',
  'sorting.json',
];

for (const filename of FIXTURE_FILES) {
  const filepath = path.join(FIXTURES_DIR, filename);
  const fixture: FixtureFile = JSON.parse(fs.readFileSync(filepath, 'utf-8'));

  describe(filename, () => {
    for (const c of fixture.cases) {
      it(`[${c.id}] ${c.name ?? c.operation}`, () => {
        const actual = runCase(c);
        expect(actual).toEqual(c.expected);
      });
    }
  });
}
