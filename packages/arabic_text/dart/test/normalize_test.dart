import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:arabic_text/arabic_text.dart';

List<Map<String, dynamic>> _casesFor(List<dynamic> cases, String operation) =>
    cases
        .whereType<Map<String, dynamic>>()
        .where((c) => c['operation'] == operation)
        .toList();

void main() {
  late List<dynamic> normalizeCases;

  setUpAll(() {
    final file = File('test/fixtures/normalize.json');
    final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    normalizeCases = raw['cases'] as List<dynamic>;
  });

  // ── 1. normalizePresentationForms ──────────────────────────────────────────
  group('normalizePresentationForms', () {
    test('fixture cases', () {
      for (final c in _casesFor(normalizeCases, 'normalizePresentationForms')) {
        expect(
          ArabicText.normalizePresentationForms(c['input'] as String),
          equals(c['expected'] as String),
          reason: '${c['id']}: ${c['name']}',
        );
      }
    });
  });

  // ── 2. removeTashkeel ──────────────────────────────────────────────────────
  group('removeTashkeel', () {
    test('fixture cases', () {
      for (final c in _casesFor(normalizeCases, 'removeTashkeel')) {
        expect(
          ArabicText.removeTashkeel(c['input'] as String),
          equals(c['expected'] as String),
          reason: '${c['id']}: ${c['name']}',
        );
      }
    });
  });

  // ── 3. removeTatweel ───────────────────────────────────────────────────────
  group('removeTatweel', () {
    test('fixture cases', () {
      for (final c in _casesFor(normalizeCases, 'removeTatweel')) {
        expect(
          ArabicText.removeTatweel(c['input'] as String),
          equals(c['expected'] as String),
          reason: '${c['id']}: ${c['name']}',
        );
      }
    });
  });

  // ── 4. normalizeAlef ───────────────────────────────────────────────────────
  group('normalizeAlef', () {
    test('fixture cases', () {
      for (final c in _casesFor(normalizeCases, 'normalizeAlef')) {
        expect(
          ArabicText.normalizeAlef(c['input'] as String),
          equals(c['expected'] as String),
          reason: '${c['id']}: ${c['name']}',
        );
      }
    });
  });

  // ── 5. normalizeHamza ──────────────────────────────────────────────────────
  group('normalizeHamza', () {
    test('fixture cases', () {
      for (final c in _casesFor(normalizeCases, 'normalizeHamza')) {
        expect(
          ArabicText.normalizeHamza(c['input'] as String),
          equals(c['expected'] as String),
          reason: '${c['id']}: ${c['name']}',
        );
      }
    });
  });

  // ── 6. normalizeYa ─────────────────────────────────────────────────────────
  group('normalizeYa', () {
    test('fixture cases', () {
      for (final c in _casesFor(normalizeCases, 'normalizeYa')) {
        expect(
          ArabicText.normalizeYa(c['input'] as String),
          equals(c['expected'] as String),
          reason: '${c['id']}: ${c['name']}',
        );
      }
    });
  });

  // ── 7. normalizeTaMarbouta ─────────────────────────────────────────────────
  group('normalizeTaMarbouta', () {
    test('fixture cases', () {
      for (final c in _casesFor(normalizeCases, 'normalizeTaMarbouta')) {
        expect(
          ArabicText.normalizeTaMarbouta(c['input'] as String),
          equals(c['expected'] as String),
          reason: '${c['id']}: ${c['name']}',
        );
      }
    });
  });

  // ── 8. normalizeDigits ─────────────────────────────────────────────────────
  group('normalizeDigits', () {
    test('fixture cases', () {
      for (final c in _casesFor(normalizeCases, 'normalizeDigits')) {
        final opts = c['options'] as Map<String, dynamic>? ?? {};
        final to = opts['to'] as String? ?? 'none';
        expect(
          ArabicText.normalizeDigits(c['input'] as String, to: to),
          equals(c['expected'] as String),
          reason: '${c['id']}: ${c['name']}',
        );
      }
    });
  });
}
