# arabic_text

مكتبة Dart لتطبيع النص العربي — تشكيل، ألفات، همزات، بحث، فرز.

بدون تبعيات خارجية. متوافقة مع [مواصفات devsamhan-arabic v1.0.1](https://github.com/devsamhan/devsamhan-arabic).

## التثبيت

```yaml
dependencies:
  arabic_text: ^1.1.0
```

```dart
import 'package:arabic_text/arabic_text.dart';
```

---

## لماذا هذه المكتبة؟

النص العربي يُكتب بأشكال متعددة لنفس الكلمة:

- `مُحَمَّد` (مشكول) ≠ `محمد` (بدون تشكيل)
- `فاطمة` (تاء مربوطة) ≠ `فاطمه` (هاء عادية)
- `أحمد` (همزة فوق) ≠ `احمد` (ألف مجردة)
- `مـحـمـد` (مع تطويل) ≠ `محمد` (بدون تطويل)

المقارنة الحرفية المباشرة ستُخفق مع كل هذه الاختلافات. هذه المكتبة تُنتج **مفاتيح موحدة** تجعل جميع هذه الأشكال تشير إلى السجل نفسه في قاعدة البيانات.

---

## الاستخدام السريع

### `toSearchKey` — مفتاح البحث للتخزين

يُزيل التشكيل والتطويل، ويُوحّد الألف والهمزة والياء. **يحافظ على التاء المربوطة (ة).**

```dart
ArabicText.toSearchKey('مُحَمَّدٌ');       // → 'محمد'
ArabicText.toSearchKey('أَبُو ظَبْيٍ');   // → 'ابو ظبي'
ArabicText.toSearchKey('إِبْرَاهِيمُ');   // → 'ابراهيم'
ArabicText.toSearchKey('فاطمة العلي');   // → 'فاطمة العلي'
```

### `toLooseSearchKey` — مفتاح البحث المتساهل (للطرفين المتساهلين)

مثل `toSearchKey` لكنه يُحوّل **ة → ه** أيضاً. استخدمه على **المفتاح المخزن المتساهل والاستعلام معاً**؛ لا تستخدمه لمقارنة عمود `toSearchKey` الصارم.

```dart
ArabicText.toLooseSearchKey('فاطمة العلي'); // → 'فاطمه العلي'
ArabicText.toLooseSearchKey('فاطمه');       // → 'فاطمه'
// كلاهما ينتج 'فاطمه' — المطابقة ستنجح فقط إذا كان العمود المخزن متساهلاً أيضاً.
```

> **تحذير:** `toSearchKey('فاطمة')` ينتج `فاطمة`، بينما `toLooseSearchKey('فاطمه')` ينتج `فاطمه`. مقارنة الاثنين تُرجع `false` دائماً. استخدم إما صارم/صارم أو متساهل/متساهل.

### `toDisplayKey` — للعرض في الواجهة

يُزيل التطويل فقط. يحافظ على التشكيل والهمزة وجميع الأحرف.

```dart
ArabicText.toDisplayKey('مـحـمـد  الأحـمـد'); // → 'محمد الأحمد'
```

### `toSlug` — معرّف URL عربي

يُنتج رابطاً آمناً يحتوي على أحرف عربية يونيكود (وليس تحويلاً لاتينياً).

```dart
ArabicText.toSlug('مدينة الرياض');       // → 'مدينه-الرياض'
ArabicText.toSlug('محمد الأحمد');        // → 'محمد-الاحمد'
ArabicText.toSlug('أبرز الأحداث 2024'); // → 'ابرز-الاحداث-2024'
```

### `normalizeName` — تطبيع الأسماء

للمطابقة وإلغاء التكرار. يُزيل التشكيل والتطويل، يُوحّد الألف والهمزة. **لا يُحوّل ة→ه ولا ى→ي** (ذات معنى في الأسماء).

```dart
ArabicText.normalizeName('مُحَمَّد');    // → 'محمد'
ArabicText.normalizeName('فَاطِمَةُ');  // → 'فاطمة'
ArabicText.normalizeName('إِبْرَاهِيم'); // → 'ابراهيم'
```

### `sort` و `compare` — الترتيب

```dart
final names = ['يوسف', 'أحمد', 'إبراهيم', 'محمد', 'آدم'];
final sorted = ArabicText.sort(names);
// → ['ابراهيم', 'احمد', 'ادم', 'محمد', 'يوسف']
// (بعد تطبيع الألف في الفرز)

// للفرز اليدوي:
names.sort(ArabicText.compare);
```

> **تحذير:** هذا ترتيب معجمي يونيكود بعد التطبيع، وليس ترتيباً قاموسياً عربياً كاملاً. ال التعريف لا يُحذف. `ArabicCollator` الكامل مقرر في إصدار مستقبلي.

### `removeTashkeel` — حذف التشكيل

```dart
ArabicText.removeTashkeel('مُحَمَّد');   // → 'محمد'
ArabicText.removeTashkeel('بِسْمِ اللَّهِ'); // → 'بسم الله'
```

### `normalizeAlef` — توحيد الألف

```dart
ArabicText.normalizeAlef('أحمد');    // → 'احمد'
ArabicText.normalizeAlef('إبراهيم'); // → 'ابراهيم'
ArabicText.normalizeAlef('آمنة');    // → 'امنة'
```

### `normalizeDigits` — تحويل الأرقام

```dart
ArabicText.normalizeDigits('١٢٣', to: 'western'); // → '123'
ArabicText.normalizeDigits('123', to: 'eastern'); // → '١٢٣'
ArabicText.normalizeDigits('۱۲۳', to: 'eastern'); // → '١٢٣' (الفارسية مصدر)
```

---

## الفرق بين `toSearchKey` و `toLooseSearchKey`

| | `toSearchKey('فاطمة')` | `toLooseSearchKey('فاطمة')` |
|---|---|---|
| النتيجة | `فاطمة` | `فاطمه` |
| يطابق `فاطمه`؟ | ❌ | ✅ |

```dart
// ❌ بحث صارم — يفشل إذا كتب المستخدم 'فاطمه'
final stored = ArabicText.toSearchKey('فاطمة العلي'); // 'فاطمة العلي'
final query  = ArabicText.toSearchKey('فاطمه');       // 'فاطمه'
stored.contains(query); // false

// ✅ بحث متساهل — ينجح مع كلا الشكلين
final stored2 = ArabicText.toLooseSearchKey('فاطمة العلي'); // 'فاطمه العلي'
final query2  = ArabicText.toLooseSearchKey('فاطمه');       // 'فاطمه'
stored2.contains(query2); // true
```

**القاعدة:** طبّق `toLooseSearchKey` على **الطرفين** — الاستعلام والبيانات — أو لا تستخدمه على أي منهما.

---

## نمط قاعدة البيانات

خزّن النص الأصلي ومفتاح البحث الصارم في عمودين منفصلين. **لا تستبدل النص الأصلي أبداً، ولا تغيّر `search_key` القائم.**

للمطابقة المتساهلة، أضف عموداً مشتقاً اختيارياً `search_key_loose` (إضافة صريحة، وليس استبدالاً للعمود الصارم):

```sql
ALTER TABLE students ADD COLUMN IF NOT EXISTS search_key_loose text;

-- املأه على دفعات. القيمة تساوي toLooseSearchKey(name) للصفوف
-- التي كتبها toSearchKey، لأن toSearchKey يحفظ ة.
UPDATE students
SET search_key_loose = replace(search_key, 'ة', 'ه')
WHERE search_key IS NOT NULL AND search_key_loose IS NULL;

-- للبحث بالبادئة فقط:
CREATE INDEX IF NOT EXISTS idx_students_loose_prefix
  ON students (search_key_loose text_pattern_ops);

-- للبحث بالاحتواء (%query%) استخدم pg_trgm وليس text_pattern_ops:
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- CREATE INDEX idx_students_loose_trgm
--   ON students USING gin (search_key_loose gin_trgm_ops);
```

```dart
// عند الحفظ: النص الأصلي + المفتاحان
await supabase.from('students').insert({
  'name': name,                                        // للعرض فقط
  'search_key': ArabicText.toSearchKey(name),          // صارم
  'search_key_loose': ArabicText.toLooseSearchKey(name), // متساهل
});

String escapeLike(String value) => value
    .replaceAll(r'\', r'\\')
    .replaceAll('%', r'\%')
    .replaceAll('_', r'\_');

// البحث المتساهل الحرفي: متساهل/متساهل — لا تستخدم search_key هنا
Future<List<Map>> searchStudentsLoose(String query) async {
  final key = ArabicText.toLooseSearchKey(query.trim());
  if (key.isEmpty) return const [];
  final pattern = '%${escapeLike(key)}%';
  return await supabase
      .from('students')
      .select()
      .like('search_key_loose', pattern);
}

// البحث الصارم: استبدل العمود بـ search_key والمفتاح بـ toSearchKey.
```

PostgREST يربط `.like()` بـ PostgreSQL `LIKE`. اختبرنا **HTTP مباشراً** محلياً مع **PostgREST 14.10 + PostgreSQL 16**:

- `*100\%*` طابق `100%` حرفياً فقط؛
- `*a\_b*` طابق `a_b` حرفياً فقط؛
- `*back\\slash*` طابق `back\slash` حرفياً.

لم تُختبر استدعاءات Supabase Dart SDK ولا خدمة Supabase المستضافة. لذلك `escapeLike` أعلاه يعمل عبر `.like()` في بيئة PostgREST المختبرة، مع تمرير النمط كقيمة (لا كـ SQL نصي). أعد اختبار إصدارك. للعميل PostgreSQL المباشر:

```dart
final pattern = '%${escapeLike(key)}%';
await db.execute(
  r"select id, name from students where search_key_loose like $1 escape '\'",
  parameters: [pattern],
);
```

إذا كان الاستعلام فارغاً، لا ترسل `%%`؛ أعد نتيجة فارغة أو تجاوز الفلتر. أما `text_pattern_ops` فيسرّع البادئات فقط، وليس `%query%`؛ للاحتواء استخدم `pg_trgm`.

---

## مرجع الـ API

| الدالة | الوصف |
|---|---|
| `toSearchKey(text)` | مفتاح بحث للتخزين. يحافظ على ة. |
| `toLooseSearchKey(text)` | مثل toSearchKey + ة→ه. للمفتاح المتساهل المخزن والاستعلام معاً. |
| `toDisplayKey(text)` | يُزيل التطويل فقط. يحافظ على التشكيل. |
| `toSlug(text)` | معرّف URL عربي آمن. |
| `normalizeName(text)` | تطبيع الأسماء. يحافظ على ى و ة. |
| `toSortKey(text)` | مفتاح فرز معجمي. |
| `sort(list)` | ترتيب قائمة بـ toSortKey. |
| `compare(a, b)` | مقارنة — يُعيد ‎-1 أو 0 أو 1. |
| `removeTashkeel(text)` | حذف جميع علامات الشكل. |
| `removeTatweel(text)` | حذف التطويل U+0640. |
| `normalizeAlef(text)` | أ إ آ ٱ → ا |
| `normalizeHamza(text)` | ؤ ئ → ء |
| `normalizeYa(text)` | ى ی → ي |
| `normalizeTaMarbouta(text)` | ة → ه. يجب استدعاؤها صراحةً. |
| `normalizeDigits(text, to:)` | تحويل الأرقام: `'western'` أو `'eastern'`. |
| `normalizePresentationForms(text)` | أشكال العرض FB50–FEFF → يونيكود قياسي. |
| `isArabic(text)` | true إذا كان النص يحتوي على أي حرف عربي. |
| `arabicRatio(text)` | نسبة الأحرف العربية (0.0–1.0). |
| `specVersion` | `'1.0.1'` |

### `ArabicNormalizeOptions` — تحكم دقيق

```dart
ArabicText.normalize(text, const ArabicNormalizeOptions(
  removeTashkeel: true,
  normalizeAlef: true,
  normalizeTaMarbouta: true, // يجب التصريح به
  normalizeDigits: 'western',
));
```

جميع الخيارات افتراضها `false` (أكثر تحفظاً). `normalizePresentationForms` افتراضها `true`.

---

## الترخيص

MIT — [Devsamhan](https://github.com/devsamhan)
