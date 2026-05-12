/// Arabic text preset pipelines — devsamhan-arabic spec v1.0.0
///
/// Processing order (SPEC §Processing Order — mandatory):
///   1. normalizePresentationForms
///   2. removeTatweel
///   3. removeTashkeel
///   4. normalizeAlef
///   5. normalizeHamza
///   6. normalizeYa  (ى + ی → ي)
///   7. normalizeTaMarbouta  (explicit-only)
///   8. normalizeDigits      (explicit-only)
///   9. trim + collapse whitespace
library;

import 'normalize.dart';

// ── Whitespace helper ─────────────────────────────────────────────────────────

String _ws(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

// ── toSearchKey ───────────────────────────────────────────────────────────────

/// Produce a normalised key for database indexing and full-text search.
///
/// Applies steps 1–6 and 9. Does NOT apply normalizeTaMarbouta or
/// normalizeDigits.
///
/// NOTE: Digits are NOT normalized in toSearchKey.
/// Eastern Arabic digits (١٢٣) and Persian digits (۱۲۳) pass through unchanged.
/// Callers who need digit normalization must call normalizeDigits() explicitly.
/// Rationale: toSearchKey is a safe normalization layer, not a search engine.
/// See SPEC.md §What Must NOT Be Normalized by Default.
String toSearchKey(String text) {
  var s = normalizePresentationForms(text); // 1
  s = removeTatweel(s); // 2
  s = removeTashkeel(s); // 3
  s = normalizeAlef(s); // 4
  s = normalizeHamza(s); // 5
  s = normalizeYa(s); // 6 — both ى (U+0649) and ی (U+06CC) → ي
  return _ws(s); // 9
}

// ── toDisplayKey ──────────────────────────────────────────────────────────────

/// Clean text for display — removes tatweel and collapses whitespace but
/// preserves tashkeel, alef/hamza/ya variants, ta marbouta, and digits.
///
/// Applies steps 1, 2, and 9 only.
String toDisplayKey(String text) {
  var s = normalizePresentationForms(text); // 1
  s = removeTatweel(s); // 2
  return _ws(s); // 9
}

// ── toSlug ────────────────────────────────────────────────────────────────────

/// Produce a URL-safe Unicode Arabic slug.
///
/// Applies all of toSearchKey, then:
///   - normalizeTaMarbouta (ة → ه — the only context where this is automatic)
///   - replace spaces with '-'
///   - lowercase Latin characters
///   - remove any char that is not Arabic (U+0600–U+06FF), a–z, 0–9, or '-'
String toSlug(String text) {
  var s = toSearchKey(text);
  s = normalizeTaMarbouta(s);
  s = s.replaceAll(' ', '-');
  s = s.toLowerCase();
  s = s.replaceAll(RegExp(r'[^؀-ۿa-z0-9-]'), '');
  return s;
}

// ── normalizeName ─────────────────────────────────────────────────────────────

/// Normalize a person's name for deduplication and matching.
///
/// Applies steps 1–5, Persian Ya only (ی U+06CC → ي), and 9.
/// Does NOT apply normalizeAlefMaqsoura (ى stays ى) or normalizeTaMarbouta.
String normalizeName(String text) {
  var s = normalizePresentationForms(text); // 1
  s = removeTatweel(s); // 2
  s = removeTashkeel(s); // 3
  s = normalizeAlef(s); // 4
  s = normalizeHamza(s); // 5
  // 6 — Persian Ya only; Alef Maqsoura (ى) is linguistically meaningful in names
  s = s.replaceAll('ی', 'ي'); // ی → ي
  return _ws(s); // 9
}

// ── toLooseSearchKey ──────────────────────────────────────────────────────────

/// Like [toSearchKey], but also normalizes Ta Marbouta (ة → ه).
///
/// Use for search *query* normalization when you want فاطمة and فاطمه to match.
///
/// ⚠️ Never use for storage. Only normalize the query side with this function.
/// Store records using [toSearchKey]; search using [toLooseSearchKey] on both
/// the stored key and the incoming query.
String toLooseSearchKey(String text) => normalizeTaMarbouta(toSearchKey(text));

// ── toSortKey ─────────────────────────────────────────────────────────────────

/// Produce a sort key for [text]. Identical pipeline to toSearchKey.
///
/// Consumers sort by comparing these keys; the original text is preserved in
/// the output of [sort].
String toSortKey(String text) => toSearchKey(text);

// ── sort ──────────────────────────────────────────────────────────────────────

/// Return a new list containing the same strings as [list] ordered by their
/// [toSortKey] values. Equal keys preserve the original relative order
/// (stable sort).
List<String> sort(List<String> list) {
  final indexed = list.indexed.toList();
  indexed.sort((a, b) {
    final cmp = toSortKey(a.$2).compareTo(toSortKey(b.$2));
    return cmp != 0 ? cmp : a.$1.compareTo(b.$1); // stable tie-break by index
  });
  return indexed.map((e) => e.$2).toList();
}

// ── compare ───────────────────────────────────────────────────────────────────

/// Compare [a] and [b] by their sort keys.
///
/// Returns `-1`, `0`, or `1` — compatible with standard comparator contracts.
int compare(String a, String b) {
  final c = toSortKey(a).compareTo(toSortKey(b));
  if (c < 0) return -1;
  if (c > 0) return 1;
  return 0;
}

// ── ArabicNormalizeOptions ────────────────────────────────────────────────────

/// Fine-grained control over normalisation. All boolean flags default to the
/// most conservative (least destructive) setting. See SPEC §ArabicNormalizeOptions.
class ArabicNormalizeOptions {
  final bool removeTashkeel;
  final bool removeTatweel;
  final bool normalizeAlef;
  final bool normalizeHamza;

  /// ى (U+0649) → ي — linguistic search normalisation.
  final bool normalizeAlefMaqsoura;

  /// ی (U+06CC) → ي — keyboard/encoding artifact normalisation.
  final bool normalizePersianYa;

  /// ة → ه — must be explicitly opted in; never automatic.
  final bool normalizeTaMarbouta;

  /// Always recommended; defaults to true.
  final bool normalizePresentationForms;

  /// `'none'` (default), `'western'`, or `'eastern'`.
  final String normalizeDigits;

  final bool trimWhitespace;
  final bool collapseWhitespace;

  const ArabicNormalizeOptions({
    this.removeTashkeel = false,
    this.removeTatweel = false,
    this.normalizeAlef = false,
    this.normalizeHamza = false,
    this.normalizeAlefMaqsoura = false,
    this.normalizePersianYa = false,
    this.normalizeTaMarbouta = false,
    this.normalizePresentationForms = true,
    this.normalizeDigits = 'none',
    this.trimWhitespace = true,
    this.collapseWhitespace = true,
  });
}

// ── normalize ─────────────────────────────────────────────────────────────────

/// Apply the normalisation steps selected by [options], in the mandatory
/// processing order defined in SPEC §Processing Order.
String normalize(String text, ArabicNormalizeOptions options) {
  var s = text;

  if (options.normalizePresentationForms)
    s = normalizePresentationForms(s); // 1
  if (options.removeTatweel) s = removeTatweel(s); // 2
  if (options.removeTashkeel) s = removeTashkeel(s); // 3
  if (options.normalizeAlef) s = normalizeAlef(s); // 4
  if (options.normalizeHamza) s = normalizeHamza(s); // 5
  if (options.normalizeAlefMaqsoura) s = s.replaceAll('ى', 'ي'); // 6a
  if (options.normalizePersianYa) s = s.replaceAll('ی', 'ي'); // 6b
  if (options.normalizeTaMarbouta) s = normalizeTaMarbouta(s); // 7
  if (options.normalizeDigits != 'none') {
    s = normalizeDigits(s, to: options.normalizeDigits); // 8
  }
  if (options.collapseWhitespace) s = s.replaceAll(RegExp(r'\s+'), ' '); // 9a
  if (options.trimWhitespace) s = s.trim(); // 9b

  return s;
}
