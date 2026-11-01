import 'dart:convert';
import 'dart:io';

import 'package:arabic_text/arabic_text.dart';
import 'package:test/test.dart';

/// AR-002 / AR-003: the official Dart harness must execute the shared numeric,
/// mixed-text, and robustness fixtures, not only normalize/search/sorting.
void main() {
  late List<dynamic> numberCases;
  late List<dynamic> mixedCases;
  late List<dynamic> robustnessCases;

  setUpAll(() {
    numberCases = _load('test/fixtures/numbers.json');
    mixedCases = _load('test/fixtures/mixed_text.json');
    robustnessCases = _load('test/fixtures/robustness.json');
  });

  group('numbers.json', () {
    test('all numeric fixture cases', () {
      for (final raw in numberCases) {
        final c = raw as Map<String, dynamic>;
        final options = (c['options'] as Map<String, dynamic>?) ?? const {};
        final actual = _run(c['operation'] as String, c['input'], options);
        expect(actual, equals(c['expected']),
            reason: '${c['id']}: ${c['name']}');
      }
    });
  });

  group('mixed_text.json', () {
    test('all mixed-text fixture cases', () {
      for (final raw in mixedCases) {
        final c = raw as Map<String, dynamic>;
        final options = (c['options'] as Map<String, dynamic>?) ?? const {};
        final actual = _run(c['operation'] as String, c['input'], options);
        expect(actual, equals(c['expected']),
            reason: '${c['id']}: ${c['name']}');
      }
    });
  });

  group('robustness.json', () {
    test('all robustness fixture cases', () {
      for (final raw in robustnessCases) {
        final c = raw as Map<String, dynamic>;
        final options = (c['options'] as Map<String, dynamic>?) ?? const {};
        final actual = _run(c['operation'] as String, c['input'], options);
        expect(actual, equals(c['expected']),
            reason: '${c['id']}: ${c['name']}');
      }
    });
  });
}

List<dynamic> _load(String path) {
  final raw = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return raw['cases'] as List<dynamic>;
}

Object? _run(String operation, Object? input, Map<String, dynamic> options) {
  final text = input as String;
  switch (operation) {
    case 'normalizeDigits':
      return ArabicText.normalizeDigits(text, to: options['to'] as String);
    case 'normalizeName':
      return ArabicText.normalizeName(text);
    case 'toSearchKey':
      return ArabicText.toSearchKey(text);
    case 'toLooseSearchKey':
      return ArabicText.toLooseSearchKey(text);
    case 'toSortKey':
      return ArabicText.toSortKey(text);
    case 'toSlug':
      return ArabicText.toSlug(text);
    case 'toDisplayKey':
      return ArabicText.toDisplayKey(text);
    case 'isArabic':
      return ArabicText.isArabic(text);
    case 'arabicRatio':
      return ArabicText.arabicRatio(text);
    default:
      throw StateError(
          'Unsupported mixed/number fixture operation: $operation');
  }
}
