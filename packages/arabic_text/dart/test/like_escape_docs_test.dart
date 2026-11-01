import 'package:test/test.dart';

// AR-010 documentation helper. This is test-only; it mirrors the copy-ready
// helper shown in the Dart README and is not a runtime API.
String escapeLike(String value) =>
    value.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

String? containsPattern(String value) =>
    value.isEmpty ? null : '%${escapeLike(value)}%';

void main() {
  group('documented LIKE escaping', () {
    test('empty query is not sent as %%', () {
      expect(escapeLike(''), '');
      expect(containsPattern(''), isNull);
    });

    test('ordinary Arabic is unchanged', () {
      expect(escapeLike('فاطمة'), 'فاطمة');
      expect(containsPattern('فاطمة'), '%فاطمة%');
    });

    test('percent is literal', () {
      expect(escapeLike('100%'), r'100\%');
      expect(containsPattern('100%'), r'%100\%%');
    });

    test('underscore is literal', () {
      expect(escapeLike('a_b'), r'a\_b');
      expect(containsPattern('a_b'), r'%a\_b%');
    });

    test('backslash is escaped first', () {
      expect(escapeLike(r'a\b'), r'a\\b');
    });

    test('all special characters together', () {
      expect(escapeLike(r'%_\'), r'\%\_\\');
    });
  });
}
