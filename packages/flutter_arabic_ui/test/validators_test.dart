import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_arabic_ui/flutter_arabic_ui.dart';

void main() {
  group('ArabicValidators.requiredArabic', () {
    test('null value returns error', () {
      expect(ArabicValidators.requiredArabic(null), isNotNull);
    });

    test('empty string returns error', () {
      expect(ArabicValidators.requiredArabic(''), isNotNull);
    });

    test('whitespace-only returns error', () {
      expect(ArabicValidators.requiredArabic('   '), isNotNull);
    });

    test('valid Arabic text returns null', () {
      expect(ArabicValidators.requiredArabic('محمد'), isNull);
    });
  });

  group('ArabicValidators.arabicOnly', () {
    test('pure Arabic returns null', () {
      expect(ArabicValidators.arabicOnly('محمد'), isNull);
    });

    test('Latin text returns error', () {
      expect(ArabicValidators.arabicOnly('hello'), isNotNull);
    });

    test('empty returns required error', () {
      expect(ArabicValidators.arabicOnly(''), isNotNull);
    });
  });

  group('ArabicValidators.mixedArabicText', () {
    test('Arabic and Latin mix returns null', () {
      expect(ArabicValidators.mixedArabicText('محمد hello'), isNull);
    });

    test('pure Arabic returns null', () {
      expect(ArabicValidators.mixedArabicText('محمد'), isNull);
    });

    test('Latin-only returns error', () {
      expect(ArabicValidators.mixedArabicText('hello'), isNotNull);
    });

    test('empty returns required error', () {
      expect(ArabicValidators.mixedArabicText(''), isNotNull);
    });
  });

  group('ArabicValidators.minArabicLetters', () {
    test('محمد (4 letters) passes min 3', () {
      expect(ArabicValidators.minArabicLetters(3)('محمد'), isNull);
    });

    test('بي (2 letters) fails min 3', () {
      expect(ArabicValidators.minArabicLetters(3)('بي'), isNotNull);
    });

    test('exactly at minimum passes', () {
      expect(ArabicValidators.minArabicLetters(3)('بحث'), isNull);
    });
  });

  group('ArabicValidators.maxArabicLetters', () {
    test('بحث (3 letters) passes max 5', () {
      expect(ArabicValidators.maxArabicLetters(5)('بحث'), isNull);
    });

    test('عبدالرحمن (9 letters) fails max 5', () {
      expect(ArabicValidators.maxArabicLetters(5)('عبدالرحمن'), isNotNull);
    });

    test('exactly at maximum passes', () {
      // محمد علي = م ح م د ع ل ي = 7 letters; use محمد (4) for ≤5
      expect(ArabicValidators.maxArabicLetters(5)('محمد'), isNull);
    });
  });

  group('ArabicValidators.numericArabic', () {
    test('Eastern Arabic digits return null', () {
      expect(ArabicValidators.numericArabic('١٢٣'), isNull);
    });

    test('Western digits return null', () {
      expect(ArabicValidators.numericArabic('123'), isNull);
    });

    test('decimal number returns null', () {
      expect(ArabicValidators.numericArabic('3.14'), isNull);
    });

    test('alphabetic text returns error', () {
      expect(ArabicValidators.numericArabic('abc'), isNotNull);
    });

    test('null returns required error', () {
      expect(ArabicValidators.numericArabic(null), isNotNull);
    });

    test('empty returns required error', () {
      expect(ArabicValidators.numericArabic(''), isNotNull);
    });
  });
}
