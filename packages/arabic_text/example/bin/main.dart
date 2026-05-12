import 'package:arabic_text/arabic_text.dart';

void main() {
  // 1. بحث في قاعدة بيانات
  final names = ['فَاطِمَةُ', 'مُحَمَّدٌ', 'إبراهيم', 'آدم', 'موسى', 'علی'];
  final query = 'فاطمه';

  final results = names
      .where((n) => ArabicText.toSearchKey(n) == ArabicText.toSearchKey(query))
      .toList();
  print('بحث عادي: $results');

  final looseResults = names
      .where((n) =>
          ArabicText.toLooseSearchKey(n) ==
          ArabicText.toLooseSearchKey(query))
      .toList();
  print('بحث متحرر: $looseResults');

  // 2. ترتيب قائمة أسماء
  final sorted = ArabicText.sort(names);
  print('مرتبة: $sorted');

  // 3. مفتاح البحث لـ Supabase
  final name = 'مُحَمَّدٌ';
  print('search_key: ${ArabicText.toSearchKey(name)}');
  print('display: $name');

  // 4. Slug للـ URL
  print('slug: ${ArabicText.toSlug('مدرسة الأمل')}');

  // 5. SPEC version
  print('spec: ${ArabicText.specVersion}');
}
