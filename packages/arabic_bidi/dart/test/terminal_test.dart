import 'package:test/test.dart';
import 'package:arabic_bidi/arabic_bidi.dart';
import 'package:arabic_text/arabic_text.dart' show ArabicText;

void main() {
  group('Arabic-only lines', () {
    test('محمد — single word reshaped', () {
      expect(ArabicBidi.prepareForTerminal('محمد'),
          equals(ArabicBidi.reshape('محمد')));
    });

    test('السلام عليكم — two words reordered for LTR terminal', () {
      // letter ratio = 11/12 ≈ 0.92 > 0.5 → dominant → runs reversed.
      expect(
          ArabicBidi.prepareForTerminal('السلام عليكم'),
          equals(
              '${ArabicBidi.reshape('عليكم')} ${ArabicBidi.reshape('السلام')}'));
    });

    test('مرحباً بالعالم — tashkeel in mid-word, words reordered', () {
      // letter ratio = 12/14 ≈ 0.86 > 0.5 → dominant → runs reversed.
      expect(
          ArabicBidi.prepareForTerminal('مرحباً بالعالم'),
          equals(
              '${ArabicBidi.reshape('بالعالم')} ${ArabicBidi.reshape('مرحباً')}'));
    });
  });

  group('Arabic with tashkeel/tatweel (transparent)', () {
    test('مُحَمَّد — same letter forms as محمد; tashkeel preserved', () {
      final withTashkeel = ArabicBidi.prepareForTerminal('مُحَمَّد');
      final plain = ArabicBidi.prepareForTerminal('محمد');
      // Tashkeel did not affect form selection; stripping it restores the plain
      // shaped result.
      expect(ArabicText.removeTashkeel(withTashkeel), equals(plain));
      // Damma (U+064F) is preserved in output.
      expect(withTashkeel.contains('ُ'), isTrue);
    });

    test('مـحـمـد — same letter forms as محمد; tatweels preserved', () {
      final withTatweel = ArabicBidi.prepareForTerminal('مـحـمـد');
      final plain = ArabicBidi.prepareForTerminal('محمد');
      expect(ArabicText.removeTatweel(withTatweel), equals(plain));
      // Tatweel (U+0640) is preserved in output.
      expect(withTatweel.contains('ـ'), isTrue);
    });
  });

  group('Arabic + numbers (NumberRun — never reshaped)', () {
    test('الطلب 123 — ASCII digits as NumberRun, dominant (5/9), reordered',
        () {
      final result = ArabicBidi.prepareForTerminal('الطلب 123');
      // letter ratio = 5/9 ≈ 0.56 > 0.5 → dominant → runs reversed.
      // "123" NumberRun moves to front as a unit; digits NOT character-reversed.
      expect(result, equals('123 ${ArabicBidi.reshape('الطلب')}'));
    });

    test('الطلب ۱۲۳ — Persian digits (U+06F1–U+06F3) as NumberRun, reordered',
        () {
      final result = ArabicBidi.prepareForTerminal('الطلب ۱۲۳');
      // U+06F1–U+06F3 → NumberRun (not ArabicRun), not reshaped.
      // letter ratio = 5/9 ≈ 0.56 > 0.5 → dominant → runs reversed.
      expect(result, equals('۱۲۳ ${ArabicBidi.reshape('الطلب')}'));
    });

    test('رقم ١٢٣ — Eastern Arabic digits (U+0661–U+0663) as NumberRun', () {
      final result = ArabicBidi.prepareForTerminal('رقم ١٢٣');
      // U+0661–U+0663 → NumberRun, not ArabicRun; not reshaped.
      // letter ratio = 3/7 ≈ 0.43 → NOT > 0.5 → no reorder.
      // Result: shaped(رقم) + space + ١٢٣ (in original order).
      expect(result, equals('${ArabicBidi.reshape('رقم')} ١٢٣'));
    });

    test('invoice ١٢٣ تم الحفظ — Eastern digits NumberRun, not dominant', () {
      final result = ArabicBidi.prepareForTerminal('invoice ١٢٣ تم الحفظ');
      // letter ratio = 7/20 = 0.35 → NOT > 0.5 → no reorder.
      // "invoice" and ١٢٣ stay in place; Arabic letter runs are shaped.
      expect(result.startsWith('invoice ١٢٣'), isTrue);
    });

    test('ملف 123 محفوظ — ASCII digits NumberRun, dominant (8/13), reordered',
        () {
      final result = ArabicBidi.prepareForTerminal('ملف 123 محفوظ');
      // letter ratio = 8/13 ≈ 0.62 > 0.5 → dominant → runs reversed.
      // "123" moves as a unit; character order preserved.
      expect(
          result,
          equals(
              '${ArabicBidi.reshape('محفوظ')} 123 ${ArabicBidi.reshape('ملف')}'));
    });
  });

  group('Arabic + Latin (Latin preserved, not reversed)', () {
    test('Error في الملف — letter ratio = 0.5, NOT dominant, no reorder', () {
      final result = ArabicBidi.prepareForTerminal('Error في الملف');
      // 7 Arabic letters / 14 total runes = 0.5 → NOT > 0.5 → no reorder.
      // "Error" stays at the start in its original character order.
      expect(result.startsWith('Error'), isTrue);
      expect(result.contains('rorrE'), isFalse);
    });

    test('تم حفظ file.txt — not dominant (5/15 ≈ 0.33), no reorder', () {
      final result = ArabicBidi.prepareForTerminal('تم حفظ file.txt');
      expect(result.contains('file.txt'), isTrue);
      expect(result.contains(ArabicBidi.reshape('تم')), isTrue);
    });

    test('invoice 123 تم الحفظ — not dominant (7/20 = 0.35), prefix unchanged',
        () {
      final result = ArabicBidi.prepareForTerminal('invoice 123 تم الحفظ');
      expect(result.startsWith('invoice'), isTrue);
      expect(result.contains('123'), isTrue);
    });
  });

  group('Arabic-dominant threshold (> 0.5, strict majority)', () {
    test('ملف ab — letter ratio = 0.5, exactly at boundary, NOT dominant', () {
      // م,ل,ف = 3 Arabic letters, ' ',a,b = 3 non-Arabic → ratio = 3/6 = 0.5.
      // 0.5 is NOT > 0.5 → no reorder; shaped Arabic stays at start.
      final result = ArabicBidi.prepareForTerminal('ملف ab');
      expect(result, equals('${ArabicBidi.reshape('ملف')} ab'));
    });

    test('ملفي ab — letter ratio ≈ 0.57, just above boundary, dominant', () {
      // م,ل,ف,ي = 4 Arabic letters, ' ',a,b = 3 non-Arabic → ratio = 4/7 ≈ 0.57.
      // > 0.5 → dominant → runs reversed.
      final result = ArabicBidi.prepareForTerminal('ملفي ab');
      expect(result, equals('ab ${ArabicBidi.reshape('ملفي')}'));
    });

    test('reorder: false always suppresses, even when ratio > 0.5', () {
      const opts = ArabicTerminalOptions(reshape: true, reorder: false);
      // السلام عليكم has letter ratio ≈ 0.92 — dominant — but reorder is off.
      final result =
          ArabicBidi.prepareForTerminal('السلام عليكم', options: opts);
      expect(
          result,
          equals(
              '${ArabicBidi.reshape('السلام')} ${ArabicBidi.reshape('عليكم')}'));
    });
  });

  group('options combinations', () {
    test('reshape: true, reorder: false — shaped, original run order kept', () {
      const opts = ArabicTerminalOptions(reshape: true, reorder: false);
      final result =
          ArabicBidi.prepareForTerminal('السلام عليكم', options: opts);
      expect(
          result,
          equals(
              '${ArabicBidi.reshape('السلام')} ${ArabicBidi.reshape('عليكم')}'));
    });

    test('reshape: false, reorder: true — runs reversed, canonical Arabic', () {
      const opts = ArabicTerminalOptions(reshape: false, reorder: true);
      final result =
          ArabicBidi.prepareForTerminal('السلام عليكم', options: opts);
      // No reshaping → canonical letters. Runs reversed → عليكم first.
      expect(result, equals('عليكم السلام'));
    });

    test('useLamAlefLigatures: true — لا becomes U+FEFB', () {
      const opts = ArabicTerminalOptions(useLamAlefLigatures: true);
      expect(ArabicBidi.prepareForTerminal('لا', options: opts), equals('ﻻ'));
    });

    test('reshapeOnly factory — reshape=true, reorder=false, no ligatures', () {
      const opts = ArabicTerminalOptions.reshapeOnly();
      expect(opts.reshape, isTrue);
      expect(opts.reorder, isFalse);
      expect(opts.useLamAlefLigatures, isFalse);
    });
  });

  group('edge cases', () {
    test('empty string', () {
      expect(ArabicBidi.prepareForTerminal(''), equals(''));
    });

    test('Latin only — unchanged', () {
      expect(
          ArabicBidi.prepareForTerminal('Hello World'), equals('Hello World'));
    });

    test('digits only — unchanged', () {
      expect(ArabicBidi.prepareForTerminal('12345'), equals('12345'));
    });

    test('single Arabic letter م', () {
      // Single letter → isolated form; single run, reorder is no-op.
      expect(
          ArabicBidi.prepareForTerminal('م'), equals(ArabicBidi.reshape('م')));
    });
  });
}
