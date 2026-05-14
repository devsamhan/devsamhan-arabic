import 'package:arabic_bidi/arabic_bidi.dart';

void main() {
  final log = ArabicLogger(prefix: 'تطبيقي');

  log.info('تم تشغيل التطبيق');
  log.warn('تحذير: الذاكرة ممتلئة');
  log.error('فشل الاتصال');

  print(ArabicBidi.prepareForTerminal('السلام عليكم'));
  print(ArabicBidi.prepareForTerminal('Error في الملف'));
}
