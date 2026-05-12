// Arabic text preset pipelines — devsamhan-arabic spec v1.0.0
//
// Processing order (mandatory per SPEC §Processing Order):
//   1. normalizePresentationForms
//   2. removeTatweel
//   3. removeTashkeel
//   4. normalizeAlef
//   5. normalizeHamza
//   6. normalizeYa  (ى + ی → ي)
//   7. normalizeTaMarbouta  (explicit-only)
//   8. normalizeDigits      (explicit-only)
//   9. trim + collapse whitespace

import {
  normalizePresentationForms,
  removeTatweel,
  removeTashkeel,
  normalizeAlef,
  normalizeHamza,
  normalizeYa,
  normalizeTaMarbouta,
} from './normalize';

function ws(s: string): string {
  return s.replace(/\s+/g, ' ').trim();
}

// ── toSearchKey ───────────────────────────────────────────────────────────────
// Applies steps 1–6 and 9. Does NOT apply normalizeTaMarbouta or normalizeDigits.
// Eastern Arabic digits (١٢٣) pass through unchanged.
export function toSearchKey(text: string): string {
  let s = normalizePresentationForms(text); // 1
  s = removeTatweel(s);                     // 2
  s = removeTashkeel(s);                    // 3
  s = normalizeAlef(s);                     // 4
  s = normalizeHamza(s);                    // 5
  s = normalizeYa(s);                       // 6
  return ws(s);                             // 9
}

// ── toLooseSearchKey ──────────────────────────────────────────────────────────
// Like toSearchKey but also converts ة → ه.
// Use for search query normalization only — never for storage.
export function toLooseSearchKey(text: string): string {
  return normalizeTaMarbouta(toSearchKey(text));
}

// ── toDisplayKey ──────────────────────────────────────────────────────────────
// Removes tatweel and collapses whitespace. Preserves tashkeel and hamza.
// Applies steps 1, 2, and 9 only.
export function toDisplayKey(text: string): string {
  let s = normalizePresentationForms(text); // 1
  s = removeTatweel(s);                     // 2
  return ws(s);                             // 9
}

// ── toSlug ────────────────────────────────────────────────────────────────────
// URL-safe Unicode Arabic slug. Not ASCII transliteration — Arabic letters kept.
export function toSlug(text: string): string {
  let s = toSearchKey(text);
  s = normalizeTaMarbouta(s);
  s = s.replace(/ /g, '-');
  s = s.toLowerCase();
  s = s.replace(/[^؀-ۿa-z0-9-]/g, '');
  return s;
}

// ── normalizeName ─────────────────────────────────────────────────────────────
// Normalize a person's name for deduplication and matching.
// Applies steps 1–5, Persian Ya only (ی → ي), and 9.
// Does NOT normalize ى (Alef Maqsoura — linguistically meaningful in names).
// Does NOT normalize ة → ه.
export function normalizeName(text: string): string {
  let s = normalizePresentationForms(text); // 1
  s = removeTatweel(s);                     // 2
  s = removeTashkeel(s);                    // 3
  s = normalizeAlef(s);                     // 4
  s = normalizeHamza(s);                    // 5
  s = s.replace(/ی/g, 'ي');       // Persian Ya only (U+06CC → U+064A)
  return ws(s);                             // 9
}

// ── toSortKey ─────────────────────────────────────────────────────────────────
// Produce a sort key. Identical pipeline to toSearchKey.
export function toSortKey(text: string): string {
  return toSearchKey(text);
}

// ── sort ──────────────────────────────────────────────────────────────────────
// Stable sort by toSortKey. Equal keys preserve original order.
export function sort(list: readonly string[]): string[] {
  const indexed = list.map((s, i) => [s, i] as [string, number]);
  indexed.sort(([a, ia], [b, ib]) => {
    const ka = toSortKey(a);
    const kb = toSortKey(b);
    if (ka < kb) return -1;
    if (ka > kb) return 1;
    return ia - ib; // stable tie-break by original index
  });
  return indexed.map(([s]) => s);
}

// ── compare ───────────────────────────────────────────────────────────────────
// Compare a and b by sort keys. Returns -1, 0, or 1.
export function compare(a: string, b: string): -1 | 0 | 1 {
  const ka = toSortKey(a);
  const kb = toSortKey(b);
  if (ka < kb) return -1;
  if (ka > kb) return 1;
  return 0;
}
