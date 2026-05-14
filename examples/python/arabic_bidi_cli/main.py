from devsamhan_arabic_bidi import prepare_for_terminal, ArabicLogger

log = ArabicLogger(prefix='تطبيقي')

log.info('تم التشغيل')
log.warn('تحذير: الذاكرة ممتلئة')
log.error('فشل الاتصال')

print(prepare_for_terminal('السلام عليكم'))
print(prepare_for_terminal('Error في الملف'))
