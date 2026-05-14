# devsamhan-arabic-text (Python)

مكتبة Python لتطبيع النص العربي — تشكيل، ألفات، همزات، بحث، فرز.

بدون تبعيات خارجية. متوافقة مع [مواصفات devsamhan-arabic v1.0.0](https://github.com/devsamhan/devsamhan-arabic).

## التثبيت

```bash
pip install devsamhan-arabic-text
```

أو محلياً:

```bash
pip install -e .
```

## الاستخدام السريع

```python
from devsamhan_arabic_text import (
    to_search_key, to_loose_search_key, to_display_key,
    to_slug, normalize_name, sort_arabic, compare_arabic,
    remove_tashkeel, normalize_alef, normalize_digits,
    is_arabic, arabic_ratio,
)

# مفتاح بحث للتخزين في قاعدة البيانات
to_search_key('مُحَمَّدٌ')       # → 'محمد'
to_search_key('فاطمة العلي')   # → 'فاطمة العلي'

# مفتاح متساهل للاستعلام (يطابق فاطمة وفاطمه)
to_loose_search_key('فاطمة')   # → 'فاطمه'

# slug لـ URL
to_slug('مدينة الرياض')        # → 'مدينه-الرياض'

# ترتيب قائمة
sort_arabic(['يوسف', 'أحمد', 'محمد'])  # → ['أحمد', 'محمد', 'يوسف']

# تحويل الأرقام
normalize_digits('١٢٣', 'western')  # → '123'
normalize_digits('123', 'eastern')  # → '١٢٣'
```

## الـ API

| الدالة | الوصف |
|---|---|
| `to_search_key(text)` | مفتاح بحث للتخزين. يحافظ على ة. |
| `to_loose_search_key(text)` | مثل to_search_key + ة→ه. للاستعلام فقط. |
| `to_display_key(text)` | يُزيل التطويل فقط. يحافظ على التشكيل. |
| `to_slug(text)` | معرّف URL عربي آمن. |
| `normalize_name(text)` | تطبيع الأسماء. يحافظ على ى و ة. |
| `to_sort_key(text)` | مفتاح فرز. |
| `sort_arabic(list)` | ترتيب مستقر بـ to_sort_key. |
| `compare_arabic(a, b)` | مقارنة — يُعيد ‎-1 أو 0 أو 1. |
| `remove_tashkeel(text)` | حذف جميع علامات الشكل. |
| `remove_tatweel(text)` | حذف التطويل U+0640. |
| `normalize_alef(text)` | أ إ آ ٱ → ا |
| `normalize_hamza(text)` | ؤ ئ → ء |
| `normalize_ya(text)` | ى ی → ي |
| `normalize_ta_marbouta(text)` | ة → ه. يجب استدعاؤها صراحةً. |
| `normalize_presentation_forms(text)` | أشكال العرض FB50–FEFF → يونيكود قياسي. |
| `normalize_digits(text, to)` | تحويل الأرقام: `'western'` أو `'eastern'`. |
| `is_arabic(text)` | True إذا كان النص يحتوي على أي حرف عربي. |
| `arabic_ratio(text)` | نسبة الأحرف العربية (0.0–1.0). |
| `SPEC_VERSION` | `'1.0.0'` |

## الترخيص

MIT — [Devsamhan](https://github.com/devsamhan)
