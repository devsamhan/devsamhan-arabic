import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:arabic_text/arabic_text.dart';

void main() {
  late List<dynamic> searchKeyCases;
  late List<dynamic> sortingCases;

  setUpAll(() {
    searchKeyCases = (jsonDecode(
      File('test/fixtures/search_key.json').readAsStringSync(),
    ) as Map<String, dynamic>)['cases'] as List<dynamic>;

    sortingCases = (jsonDecode(
      File('test/fixtures/sorting.json').readAsStringSync(),
    ) as Map<String, dynamic>)['cases'] as List<dynamic>;
  });

  // ── toSearchKey ─────────────────────────────────────────────────────────────
  group('toSearchKey', () {
    test('fixture cases (search_key.json)', () {
      for (final raw in searchKeyCases) {
        final c = raw as Map<String, dynamic>;
        if (c['operation'] != 'toSearchKey') continue;
        expect(
          ArabicText.toSearchKey(c['input'] as String),
          equals(c['expected'] as String),
          reason: '${c['id']}: ${c['name']}',
        );
      }
    });
  });

  // ── toLooseSearchKey ────────────────────────────────────────────────────────
  group('toLooseSearchKey', () {
    test('fixture cases (search_key.json)', () {
      for (final raw in searchKeyCases) {
        final c = raw as Map<String, dynamic>;
        if (c['operation'] != 'toLooseSearchKey') continue;
        expect(
          ArabicText.toLooseSearchKey(c['input'] as String),
          equals(c['expected'] as String),
          reason: '${c['id']}: ${c['name']}',
        );
      }
    });
  });

  // ── toSortKey ───────────────────────────────────────────────────────────────
  group('toSortKey', () {
    test('all cases (sorting.json)', () {
      for (final raw in sortingCases) {
        final c = raw as Map<String, dynamic>;
        if (c['operation'] != 'toSortKey') continue;
        final input = c['input'];
        final expected = c['expected'];
        if (input is String) {
          expect(ArabicText.toSortKey(input), equals(expected as String),
              reason: '${c['id']}: ${c['name']}');
        } else if (input is List) {
          final result =
              input.cast<String>().map(ArabicText.toSortKey).toList();
          expect(result, equals((expected as List<dynamic>).cast<String>()),
              reason: '${c['id']}: ${c['name']}');
        }
      }
    });
  });

  // ── sort — one subtest per fixture case so all failures are visible ─────────
  group('sort', () {
    late List<Map<String, dynamic>> cases;
    setUpAll(() {
      cases = sortingCases
          .whereType<Map<String, dynamic>>()
          .where((c) => c['operation'] == 'sort')
          .toList();
    });
    test('sort-list-001', () {
      final c = cases.firstWhere((c) => c['id'] == 'sort-list-001');
      expect(ArabicText.sort((c['input'] as List).cast<String>()),
          equals((c['expected'] as List).cast<String>()),
          reason: 'sort-list-001');
    });
    test('sort-list-002', () {
      final c = cases.firstWhere((c) => c['id'] == 'sort-list-002');
      expect(ArabicText.sort((c['input'] as List).cast<String>()),
          equals((c['expected'] as List).cast<String>()),
          reason: 'sort-list-002');
    });
    test('sort-list-003', () {
      final c = cases.firstWhere((c) => c['id'] == 'sort-list-003');
      expect(ArabicText.sort((c['input'] as List).cast<String>()),
          equals((c['expected'] as List).cast<String>()),
          reason: 'sort-list-003');
    });
  });

  // ── compare ─────────────────────────────────────────────────────────────────
  group('compare', () {
    test('fixture cases (sorting.json)', () {
      for (final raw in sortingCases) {
        final c = raw as Map<String, dynamic>;
        if (c['operation'] != 'compare') continue;
        final pair = (c['input'] as List<dynamic>).cast<String>();
        expect(
            ArabicText.compare(pair[0], pair[1]), equals(c['expected'] as int),
            reason: '${c['id']}: ${c['name']}');
      }
    });
  });
}
