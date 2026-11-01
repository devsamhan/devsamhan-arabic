import 'dart:convert';
import 'dart:io';

import '../../packages/arabic_text/dart/lib/arabic_text.dart';

String cps(String value) => value.runes
    .map((r) => 'U+${r.toRadixString(16).toUpperCase().padLeft(4, '0')}')
    .join(' ');

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: dart run tools/parity/run_dart.dart <corpus> <out>');
    exit(2);
  }
  final corpus = jsonDecode(File(args[0]).readAsStringSync()) as Map<String, dynamic>;
  final ops = <String, String Function(String)>{
    'toSearchKey': ArabicText.toSearchKey,
    'toLooseSearchKey': ArabicText.toLooseSearchKey,
    'normalizeName': ArabicText.normalizeName,
    'toDisplayKey': ArabicText.toDisplayKey,
    'toSlug': ArabicText.toSlug,
    'removeTashkeel': ArabicText.removeTashkeel,
    'removeTatweel': ArabicText.removeTatweel,
    'normalizeAlef': ArabicText.normalizeAlef,
    'normalizeHamza': ArabicText.normalizeHamza,
    'normalizeYa': ArabicText.normalizeYa,
    'normalizeTaMarbouta': ArabicText.normalizeTaMarbouta,
    'normalizePresentationForms': ArabicText.normalizePresentationForms,
    'digitsWestern': (s) => ArabicText.normalizeDigits(s, to: 'western'),
    'digitsEastern': (s) => ArabicText.normalizeDigits(s, to: 'eastern'),
  };
  final rows = <Map<String, Object?>>[];
  for (final item in (corpus['inputs'] as List).cast<Map<String, dynamic>>()) {
    final text = item['text'] as String;
    for (final name in (corpus['operations'] as List).cast<String>()) {
      final output = ops[name]!(text);
      rows.add({
        'id': item['id'],
        'operation': name,
        'input': text,
        'output': output,
        'codepoints': cps(output),
      });
    }
  }
  File(args[1]).writeAsStringSync(
    const JsonEncoder.withIndent(' ').convert({
      'impl': 'dart',
      'seed': corpus['seed'],
      'results': rows,
    }),
  );
  print('DART_RESULTS ${rows.length}');
}
