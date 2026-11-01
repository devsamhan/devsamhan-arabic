# devsamhan-arabic-text (Python)

مكتبة Python لتطبيع النص العربي — تشكيل، ألفات، همزات، بحث، فرز.

بدون تبعيات خارجية. متوافقة مع [مواصفات devsamhan-arabic v1.0.1](https://github.com/devsamhan/devsamhan-arabic).

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

# مفتاح متساهل: طبّقه على المفتاح المخزن المتساهل والاستعلام معاً
to_loose_search_key('فاطمة')   # → 'فاطمه'
to_loose_search_key('فاطمه')   # → 'فاطمه'
# ⚠️ لا تقارن هذا المفتاح بعمود to_search_key الصارم؛ استخدم عموداً متساهلاً.

# slug لـ URL
to_slug('مدينة الرياض')        # → 'مدينه-الرياض'

# ترتيب قائمة
sort_arabic(['يوسف', 'أحمد', 'محمد'])  # → ['أحمد', 'محمد', 'يوسف']

# تحويل الأرقام
normalize_digits('١٢٣', 'western')  # → '123'
normalize_digits('123', 'eastern')  # → '١٢٣'
normalize_digits('۱۲۳', 'eastern')  # → '١٢٣' (Persian is a source)
```

## نمط قاعدة البيانات

خزّن النص الأصلي ومفتاحاً صارماً، وأضف عموداً متساهلاً اختيارياً. لا تغيّر `search_key` القائم.

```sql
ALTER TABLE students ADD COLUMN IF NOT EXISTS search_key_loose text;
UPDATE students SET search_key_loose = replace(search_key, 'ة', 'ه')
WHERE search_key IS NOT NULL AND search_key_loose IS NULL;
```

```python
# حفظ: النص الأصلي + المفتاحان
cur.execute(
    "INSERT INTO students (name, search_key, search_key_loose) VALUES (%s, %s, %s)",
    (name, to_search_key(name), to_loose_search_key(name)),
)


def escape_like(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace("%", "\\%")
        .replace("_", "\\_")
    )


# بحث متساهل حرفي: متساهل/متساهل — لا تستخدم search_key هنا
key = to_loose_search_key(query.strip())
if not key:
    rows = []
else:
    pattern = f"%{escape_like(key)}%"
    cur.execute(
        "SELECT id, name FROM students "
        "WHERE search_key_loose LIKE %s ESCAPE '\\'",
        (pattern,),
    )
    rows = cur.fetchall()
```

```sql
-- PostgreSQL: $1 هو النمط الكامل بعد escape_like، وليس المفتاح الخام
SELECT id, name FROM students
WHERE search_key_loose LIKE $1 ESCAPE '\';
```

`text_pattern_ops` يسرّع البادئات فقط. للاحتواء `%query%` استخدم `pg_trgm`. لا تدمج مدخل المستخدم في SQL نصياً. إذا كان الاستعلام فارغاً، لا ترسل `%%`؛ أعد نتيجة فارغة أو تجاوز الفلتر.

> **PostgREST/Supabase:** اختبر R1 محلياً **HTTP مباشر إلى PostgREST 14.10 + PostgreSQL 16**، ووجد أن `.like()` يحترم فرار `\` لـ `%` و`_` و`\`. لم تُختبر استدعاءات Supabase SDK أو الخدمة المستضافة. المثال أعلاه يستخدم `psycopg` مباشرة؛ أعد اختبار إصدارك عند استخدام SDK.

## الـ API

| الدالة | الوصف |
|---|---|
| `to_search_key(text)` | مفتاح بحث للتخزين. يحافظ على ة. |
| `to_loose_search_key(text)` | مثل to_search_key + ة→ه. للمفتاح المتساهل المخزن والاستعلام معاً. |
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
| `SPEC_VERSION` | `'1.0.1'` |

## الترخيص

MIT — [Devsamhan](https://github.com/devsamhan)
