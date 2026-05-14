# devsamhan-arabic-bidi

مكتبة Python لعرض النص العربي صحيحاً في الطرفية — إعادة تشكيل الحروف، كشف الاتجاه، سجل عربي.

بدون أي تبعيات خارجية. متوافقة مع [مواصفات devsamhan-arabic v1.0.0](https://github.com/devsamhan/devsamhan-arabic).

## التثبيت

```bash
pip install devsamhan-arabic-bidi
```

```python
from devsamhan_arabic_bidi import (
    reshape, prepare_for_terminal, print_arabic,
    detect_direction,
    ArabicLogger, arabic_logger,
)
```

---

## الاستخدام السريع

```python
# إعادة تشكيل الحروف (الحروف المعزولة → أشكال السياق)
reshape('بيت')                             # → 'ﺑﻴﺖ'

# تجهيز النص للطرفية (تشكيل + إعادة ترتيب المقاطع)
prepare_for_terminal('مرحبا Hello')        # → 'Hello ﻢﺭﻍﺻﺎ'

# طباعة مباشرة
print_arabic('مرحبا بالعالم')

# كشف الاتجاه
detect_direction('مرحبا')   # → 'rtl'
detect_direction('Hello')   # → 'ltr'
detect_direction('Hi مرحبا')# → 'mixed'

# سجل عربي
arabic_logger.info('تم التشغيل')
ArabicLogger(prefix='خادم', use_timestamp=True).error('فشل الاتصال')
```

---

## الـ API

| الدالة | الوصف |
|---|---|
| `reshape(text, *, use_lam_alef_ligatures=False)` | تحويل الحروف إلى أشكال السياق. |
| `prepare_for_terminal(text, *, do_reshape=True, reorder=True, use_lam_alef_ligatures=False)` | تشكيل + إعادة ترتيب مقاطع النص لعرض صحيح في الطرفية. |
| `print_arabic(text, **kwargs)` | طباعة النص بعد التجهيز. |
| `detect_direction(text)` | يُعيد `'rtl'` أو `'ltr'` أو `'mixed'`. |
| `arabic_logger` | نسخة جاهزة من `ArabicLogger`. |

### ArabicLogger

```python
ArabicLogger(
    prefix=None,           # يُضاف بين قوسين قبل المستوى
    use_timestamp=False,   # إضافة الطابع الزمني
    do_reshape=True,
    reorder=True,
    use_lam_alef_ligatures=False,
)
```

تنسيق المخرجات: `[yyyy-MM-dd HH:mm:ss][prefix][LEVEL] message`

---

## الفرق عن النسخة TypeScript

تستخدم هذه المكتبة نسبة الحروف العربية (U+0621–U+063A, U+0641–U+064A) مقسومةً على عدد المحارف غير المسافة (بدلاً من جميع محارف U+0600–U+06FF مقسومةً على الكل)، لتقرير إعادة ترتيب المقاطع.

مثال: `'رقم ١٢٣'` لا يُعاد ترتيبه في Python (3 حروف / 6 غير-مسافة = 0.5، غير أكبر صراحةً من 0.5)، بينما يُعاد ترتيبه في TypeScript.

---

## الترخيص

MIT — [Devsamhan](https://github.com/devsamhan)
