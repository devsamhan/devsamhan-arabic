# @devsamhan/arabic-text

مكتبة JavaScript/TypeScript لتطبيع النص العربي — تشكيل، ألفات، همزات، بحث، فرز.

بدون تبعيات خارجية. متوافقة مع [مواصفات devsamhan-arabic v1.0.1](https://github.com/devsamhan/devsamhan-arabic).

## التثبيت

```bash
npm install @devsamhan/arabic-text
```

```typescript
import {
  toSearchKey, toLooseSearchKey, toDisplayKey,
  toSlug, normalizeName, sort, compare,
  removeTashkeel, normalizeAlef, normalizeDigits,
  isArabic, arabicRatio,
} from '@devsamhan/arabic-text';
```

---

## الاستخدام السريع

```typescript
// مفتاح بحث للتخزين في قاعدة البيانات
toSearchKey('مُحَمَّدٌ');       // → 'محمد'
toSearchKey('فاطمة العلي');   // → 'فاطمة العلي'

// مفتاح متساهل: طبّقه على المفتاح المخزن المتساهل والاستعلام معاً
toLooseSearchKey('فاطمة');    // → 'فاطمه'
toLooseSearchKey('فاطمه');    // → 'فاطمه'
// ⚠️ لا تقارن هذا المفتاح بعمود toSearchKey الصارم؛ استخدم عموداً متساهلاً.

// slug لـ URL
toSlug('مدينة الرياض');       // → 'مدينه-الرياض'

// ترتيب قائمة
sort(['يوسف', 'أحمد', 'محمد']); // → ['أحمد', 'محمد', 'يوسف']

// تحويل الأرقام
normalizeDigits('١٢٣', 'western'); // → '123'
normalizeDigits('123', 'eastern'); // → '١٢٣'
normalizeDigits('۱۲۳', 'eastern'); // → '١٢٣' (Persian is a source)
```

---

## الـ API

| الدالة | الوصف |
|---|---|
| `toSearchKey(text)` | مفتاح بحث للتخزين. يحافظ على ة. |
| `toLooseSearchKey(text)` | مثل toSearchKey + ة→ه. للمفتاح المتساهل المخزن والاستعلام معاً. |
| `toDisplayKey(text)` | يُزيل التطويل فقط. يحافظ على التشكيل. |
| `toSlug(text)` | معرّف URL عربي آمن. |
| `normalizeName(text)` | تطبيع الأسماء. يحافظ على ى و ة. |
| `toSortKey(text)` | مفتاح فرز. |
| `sort(list)` | ترتيب مستقر بـ toSortKey. |
| `compare(a, b)` | مقارنة — يُعيد ‎-1 أو 0 أو 1. |
| `removeTashkeel(text)` | حذف جميع علامات الشكل. |
| `removeTatweel(text)` | حذف التطويل U+0640. |
| `normalizeAlef(text)` | أ إ آ ٱ → ا |
| `normalizeHamza(text)` | ؤ ئ → ء |
| `normalizeYa(text)` | ى ی → ي |
| `normalizeTaMarbouta(text)` | ة → ه. يجب استدعاؤها صراحةً. |
| `normalizePresentationForms(text)` | أشكال العرض FB50–FEFF → يونيكود قياسي. |
| `normalizeDigits(text, to)` | تحويل الأرقام: `'western'` أو `'eastern'`. |
| `isArabic(text)` | true إذا كان النص يحتوي على أي حرف عربي. |
| `arabicRatio(text)` | نسبة الأحرف العربية (0.0–1.0). |
| `specVersion` | `'1.0.1'` |

---

## نمط قاعدة البيانات

خزّن النص الأصلي ومفتاحاً صارماً، وأضف عموداً متساهلاً اختيارياً. لا تغيّر `search_key` القائم.

```typescript
// عند الحفظ: النص الأصلي + المفتاحان
await db.insert({
  name,                                        // للعرض فقط
  search_key: toSearchKey(name),               // صارم
  search_key_loose: toLooseSearchKey(name),    // متساهل
});

const escapeLike = (value: string): string =>
  value
    .replace(/\\/g, '\\\\')
    .replace(/%/g, '\\%')
    .replace(/_/g, '\\_');

type QueryAdapter = {
  query: (sql: string, params: unknown[]) => Promise<unknown[]>;
};

// بحث حرفي: الاستعلام الفارغ يتوقف قبل أي طلب قاعدة بيانات.
async function searchStudentsLoose(
  db: QueryAdapter,
  query: string,
): Promise<unknown[]> {
  const key = toLooseSearchKey(query.trim());
  if (key.length === 0) return [];

  const pattern = `%${escapeLike(key)}%`;
  return db.query(
    "select id, name from students where search_key_loose like $1 escape '\\'",
    [pattern],
  );
}

// const rows = await searchStudentsLoose(db, query);
// للبحث الصارم استخدم toSearchKey و search_key مع نفس الحارس.
```

```sql
ALTER TABLE students ADD COLUMN IF NOT EXISTS search_key_loose text;
UPDATE students SET search_key_loose = replace(search_key, 'ة', 'ه')
WHERE search_key IS NOT NULL AND search_key_loose IS NULL;

-- $1 هو النمط الكامل بعد escapeLike، وليس المفتاح الخام
SELECT id, name FROM students
WHERE search_key_loose LIKE $1 ESCAPE '\';
```

`text_pattern_ops` يسرّع البدايات فقط. للاحتواء `%query%` استخدم `pg_trgm` وفهرس GIN/GiST مناسباً. لا تدمج مدخل المستخدم في SQL نصياً. إذا كان الاستعلام فارغاً، لا ترسل `%%`؛ أعد نتيجة فارغة أو تجاوز الفلتر.

> **PostgREST/Supabase:** اختبر R1 محلياً **HTTP مباشر إلى PostgREST 14.10 + PostgreSQL 16**، ووجد أن `\.like()` يحترم فرار `\` لـ `%` و`_` و`\`. لم تُختبر هنا استدعاءات Supabase JS/Dart SDK ولا خدمة Supabase المستضافة. المثال أعلاه يستخدم مشغّل SQL مباشراً؛ إذا استخدمت `.like()` من SDK، أعد اختبار إصدارك.

---

## الترخيص

MIT — [Devsamhan](https://github.com/devsamhan)
