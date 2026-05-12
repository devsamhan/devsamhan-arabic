/// Arabic text normalization library — devsamhan-arabic spec v1.0.0.
///
/// Primary entry point: [ArabicText] static class.
library arabic_text;

export 'src/normalize.dart' show specVersion;
export 'src/presets.dart' show ArabicNormalizeOptions;

import 'src/normalize.dart' as _n;
import 'src/presets.dart' as _p;

/// Static facade over all arabic_text functions.
///
/// Every method delegates to the underlying top-level function with the same
/// name. Import this class for a single-namespace API, or call the top-level
/// functions directly.
abstract final class ArabicText {
  // ── Spec version ──────────────────────────────────────────────────────────

  /// Version of the devsamhan-arabic behavioral spec this implementation
  /// conforms to. Compare this against your expected spec version in tests.
  static const String specVersion = _n.specVersion;

  // ── Surgical functions ────────────────────────────────────────────────────

  /// Convert Arabic Presentation Forms (U+FB50–U+FDFF, U+FE70–U+FEFF) to
  /// their canonical Unicode equivalents. Always safe to apply.
  static String normalizePresentationForms(String text) =>
      _n.normalizePresentationForms(text);

  /// Remove all Arabic diacritics (tashkeel) including short vowels, tanwin,
  /// shadda, sukun, and Quranic annotation marks.
  static String removeTashkeel(String text) => _n.removeTashkeel(text);

  /// Remove tatweel / kashida (U+0640). Preserves the Quranic ـٰ sequence
  /// (tatweel + superscript alef) to avoid corrupting Quranic annotations.
  static String removeTatweel(String text) => _n.removeTatweel(text);

  /// Normalize Alef variants (أ إ آ ٱ) to bare Alef (ا).
  static String normalizeAlef(String text) => _n.normalizeAlef(text);

  /// Normalize hamza-on-waw (ؤ) and hamza-on-ya (ئ) to bare hamza (ء).
  /// Does not touch أ / إ — those are handled by [normalizeAlef].
  static String normalizeHamza(String text) => _n.normalizeHamza(text);

  /// Normalize Alef Maqsoura (ى U+0649) and Persian/Urdu Yeh (ی U+06CC)
  /// to Arabic Yeh (ي U+064A).
  static String normalizeYa(String text) => _n.normalizeYa(text);

  /// Convert Ta Marbouta (ة) to Ha (ه).
  ///
  /// Explicit-only. Never called automatically by any preset except [toSlug].
  /// Never use this for storage normalization.
  static String normalizeTaMarbouta(String text) =>
      _n.normalizeTaMarbouta(text);

  /// Convert digits between Eastern Arabic / Persian and Western forms.
  ///
  /// [to] must be `'western'` or `'eastern'`. Eastern Arabic (U+0660–U+0669)
  /// and Extended Persian (U+06F0–U+06F9) are both recognized as source forms
  /// when converting to Western.
  static String normalizeDigits(String text, {required String to}) =>
      _n.normalizeDigits(text, to: to);

  // ── Presets ───────────────────────────────────────────────────────────────

  /// Produce a normalized key for database indexing and full-text search.
  ///
  /// Applies: presentation forms, tatweel, tashkeel, alef, hamza, ya,
  /// whitespace collapse. Preserves ة by default. See [toLooseSearchKey].
  ///
  /// Digits are NOT normalized — Eastern Arabic digits pass through unchanged.
  /// Call [normalizeDigits] explicitly if digit normalization is needed.
  static String toSearchKey(String text) => _p.toSearchKey(text);

  /// Like [toSearchKey] but also converts ة → ه.
  ///
  /// Use for query normalization only, not storage. Store records with
  /// [toSearchKey]; normalize the incoming query with [toLooseSearchKey]
  /// so that فاطمة and فاطمه match the same records.
  static String toLooseSearchKey(String text) => _p.toLooseSearchKey(text);

  /// Clean text for display — removes tatweel and collapses whitespace.
  ///
  /// Removes tatweel only. Preserves tashkeel and hamza. Does not alter
  /// alef variants, ya, ta marbouta, or digits.
  static String toDisplayKey(String text) => _p.toDisplayKey(text);

  /// Produce a URL-safe Unicode Arabic slug.
  ///
  /// Applies all of [toSearchKey], then converts ة → ه, replaces spaces with
  /// `-`, lowercases Latin characters, and removes any character that is not
  /// an Arabic letter, a–z, 0–9, or `-`.
  ///
  /// This is NOT ASCII transliteration — Arabic letters are kept in Unicode.
  static String toSlug(String text) => _p.toSlug(text);

  /// Normalize a person's name for deduplication and matching.
  ///
  /// Applies: presentation forms, tatweel, tashkeel, alef, hamza, Persian ی.
  /// Does NOT normalize ى → ي (Alef Maqsoura is linguistically meaningful
  /// in names) and does NOT normalize ة → ه.
  static String normalizeName(String text) => _p.normalizeName(text);

  /// Produce a sort key for [text] suitable for stable lexical ordering.
  ///
  /// Normalized lexical sort key. Not locale-aware collation. Uses the same
  /// pipeline as [toSearchKey]. Words are ordered by Unicode code unit values
  /// after normalization — this is NOT full Arabic dictionary order.
  /// Full Arabic collation (ArabicCollator) is deferred to a future version.
  static String toSortKey(String text) => _p.toSortKey(text);

  /// Return a new list with the same strings sorted by their [toSortKey]
  /// values. Equal keys preserve original relative order (stable sort).
  ///
  /// **Warning:** this is normalized Unicode lexical order, not Arabic
  /// dictionary order. The definite article (ال) is not stripped, and
  /// ة / ه sort separately. Do not advertise this as "Arabic alphabetical."
  static List<String> sort(List<String> list) => _p.sort(list);

  /// Compare [a] and [b] by their sort keys. Returns `-1`, `0`, or `1`.
  static int compare(String a, String b) => _p.compare(a, b);

  /// Apply the normalizations selected by [options] in the mandatory
  /// processing order defined in the spec.
  static String normalize(String text, _p.ArabicNormalizeOptions options) =>
      _p.normalize(text, options);

  // ── Utilities ─────────────────────────────────────────────────────────────

  /// Return `true` if [text] contains at least one Arabic-block code point
  /// (U+0600–U+06FF).
  static bool isArabic(String text) => RegExp(r'[؀-ۿ]').hasMatch(text);

  /// Return the fraction of code points in [text] that fall in the Arabic
  /// block (U+0600–U+06FF). Returns `0.0` for empty strings.
  static double arabicRatio(String text) {
    if (text.isEmpty) return 0.0;
    final arabic = text.runes.where((r) => r >= 0x0600 && r <= 0x06FF).length;
    return arabic / text.runes.length;
  }
}
