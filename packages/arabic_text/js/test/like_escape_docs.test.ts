import { describe, it, expect } from 'vitest';
import { toLooseSearchKey } from '../src/index';

// AR-010: this mirrors the copy-ready TypeScript search example exactly. The
// database adapter is a stub so the test can prove empty input never queries.
const escapeLike = (value: string): string =>
  value
    .replace(/\\/g, '\\\\')
    .replace(/%/g, '\\%')
    .replace(/_/g, '\\_');

type QueryAdapter = {
  query: (sql: string, params: unknown[]) => Promise<unknown[]>;
};

async function searchStudentsLoose(
  db: QueryAdapter,
  query: string,
): Promise<unknown[]> {
  const key = toLooseSearchKey(query.trim());
  if (key.length === 0) return [];
  const pattern = `%${escapeLike(key)}%`;
  return db.query(
    "select id, name from students where search_key_loose like $1 escape '\\'",
    [pattern],
  );
}

function fakeDb() {
  const calls: Array<{ sql: string; params: unknown[] }> = [];
  const db: QueryAdapter = {
    query: async (sql, params) => {
      calls.push({ sql, params });
      return [];
    },
  };
  return { db, calls };
}

describe('documented searchStudentsLoose', () => {
  it('empty and whitespace queries issue zero database calls', async () => {
    const { db, calls } = fakeDb();
    await expect(searchStudentsLoose(db, '')).resolves.toEqual([]);
    await expect(searchStudentsLoose(db, '   ')).resolves.toEqual([]);
    expect(calls).toHaveLength(0);
  });

  it('ordinary Arabic produces a normalized bound pattern', async () => {
    const { db, calls } = fakeDb();
    await searchStudentsLoose(db, 'فاطمة');
    expect(calls).toHaveLength(1);
    expect(calls[0].params).toEqual(['%فاطمه%']);
  });

  it('literal percent is escaped in the bound pattern', async () => {
    const { db, calls } = fakeDb();
    await searchStudentsLoose(db, '100%');
    expect(calls[0].params).toEqual(['%100\\%%']);
  });

  it('literal underscore is escaped in the bound pattern', async () => {
    const { db, calls } = fakeDb();
    await searchStudentsLoose(db, 'a_b');
    expect(calls[0].params).toEqual(['%a\\_b%']);
  });

  it('literal backslash is escaped first', async () => {
    const { db, calls } = fakeDb();
    await searchStudentsLoose(db, 'a\\b');
    expect(calls[0].params).toEqual(['%a\\\\b%']);
  });

  it('SQL uses one bound parameter and explicit ESCAPE', async () => {
    const { db, calls } = fakeDb();
    await searchStudentsLoose(db, 'فاطمة');
    expect(calls[0].sql).toBe(
      "select id, name from students where search_key_loose like $1 escape '\\'",
    );
    expect(calls[0].params).toHaveLength(1);
  });
});
