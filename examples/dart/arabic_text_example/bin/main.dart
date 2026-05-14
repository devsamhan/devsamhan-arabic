import 'package:arabic_text/arabic_text.dart';

void main() {
  // بحث عربي مرن داخل قائمة أسماء
  final names = ['فَاطِمَةُ العلي', 'مُحَمَّد أحمد', 'إبراهيم السالم'];
  final query = 'فاطمه';

  final results = names
      .where(
        (name) => ArabicText.toLooseSearchKey(
          name,
        ).contains(ArabicText.toLooseSearchKey(query)),
      )
      .toList();

  print('نتائج البحث: $results');
  print('مفتاح البحث: ${ArabicText.toSearchKey('مُحَمَّدٌ')}');
  print('slug: ${ArabicText.toSlug('مدرسة الأمل')}');
  print('مرتبة: ${ArabicText.sort(names)}');
}
