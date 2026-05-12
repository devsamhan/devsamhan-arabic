import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_text/arabic_text.dart';
import 'package:flutter_arabic_ui/flutter_arabic_ui.dart';

void main() {
  group('ArabicTextEditingController', () {
    test('searchKey returns toSearchKey', () {
      final c = ArabicTextEditingController(text: 'مُحَمَّد');
      addTearDown(c.dispose);
      expect(c.searchKey, equals(ArabicText.toSearchKey('مُحَمَّد')));
    });

    test('looseSearchKey returns toLooseSearchKey', () {
      final c = ArabicTextEditingController(text: 'فاطمة');
      addTearDown(c.dispose);
      expect(c.looseSearchKey, equals(ArabicText.toLooseSearchKey('فاطمة')));
    });

    test('displayKey returns toDisplayKey', () {
      final c = ArabicTextEditingController(text: 'مـحـمـد');
      addTearDown(c.dispose);
      expect(c.displayKey, equals(ArabicText.toDisplayKey('مـحـمـد')));
    });

    test('slug returns toSlug', () {
      final c = ArabicTextEditingController(text: 'محمد علي');
      addTearDown(c.dispose);
      expect(c.slug, equals(ArabicText.toSlug('محمد علي')));
    });

    test('normalizeInPlace changes text explicitly', () {
      final c = ArabicTextEditingController(text: 'مُحَمَّد');
      addTearDown(c.dispose);
      c.normalizeInPlace(
        const ArabicNormalizeOptions(removeTashkeel: true, removeTatweel: true),
      );
      expect(c.text, equals('محمد'));
    });

    test('text not mutated automatically on change', () {
      final c = ArabicTextEditingController();
      addTearDown(c.dispose);
      c.text = 'مُحَمَّد';
      expect(c.text, equals('مُحَمَّد'));
    });
  });

  group('ArabicSearchController', () {
    test('searchKey correct', () {
      final c = ArabicSearchController(text: 'مُحَمَّد');
      addTearDown(c.dispose);
      expect(c.searchKey, equals(ArabicText.toSearchKey('مُحَمَّد')));
    });

    test('looseSearchKey correct', () {
      final c = ArabicSearchController(text: 'فاطمة');
      addTearDown(c.dispose);
      expect(c.looseSearchKey, equals(ArabicText.toLooseSearchKey('فاطمة')));
    });

    test('visible text never auto-mutated', () {
      final c = ArabicSearchController();
      addTearDown(c.dispose);
      c.text = 'مُحَمَّد';
      expect(c.text, equals('مُحَمَّد'));
    });
  });
}
