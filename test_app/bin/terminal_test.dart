import 'package:arabic_bidi/arabic_bidi.dart';

void main() {
  final lines = [
    'محمد',
    'السلام عليكم',
    'مُحَمَّد',
    'مـحـمـد',
    'Error في الملف',
    'تم حفظ file.txt',
    'الطلب رقم 123',
    'رقم ١٢٣ هاتف',
    'invoice ١٢٣ تم الحفظ',
    'فاطمة العلي',
    'نُورَة الشمري',
  ];

  print('═══ بدون arabic_bidi ═══');
  for (final line in lines) {
    print(line);
  }

  print('');
  print('═══ مع arabic_bidi.prepareForTerminal ═══');
  for (final line in lines) {
    print(ArabicBidi.prepareForTerminal(line));
  }

  print('');
  print('═══ اتجاه النص ═══');
  for (final line in lines) {
    final dir = ArabicBidi.detectDirection(line);
    print('${ArabicBidi.prepareForTerminal(line)}  ← $dir');
  }

  print('');
  print('═══ ArabicLogger ═══');
  final log = ArabicLogger(prefix: 'حصتي');
  log.info('تم تسجيل المدرس بنجاح');
  log.warn('الجلسة على وشك الانتهاء');
  log.error('فشل الاتصال بقاعدة البيانات');
}
