import { prepareForTerminal, ArabicLogger } from '@devsamhan/arabic-bidi';

const log = new ArabicLogger({ prefix: 'تطبيقي' });

log.info('تم التشغيل');
log.warn('تحذير: الذاكرة ممتلئة');
log.error('فشل الاتصال');

console.log(prepareForTerminal('السلام عليكم'));
console.log(prepareForTerminal('Error في الملف'));
