# arabic_text

مكتبة Dart لتطبيع النص العربي — تشكيل، ألفات، همزات، بحث، فرز.

بدون تبعيات خارجية. متوافقة مع [مواصفات devsamhan-arabic v1.0.0](https://github.com/devsamhan/devsamhan-arabic).

## التثبيت

```yaml
dependencies:
  arabic_text: ^1.0.0
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

### `toLooseSearchKey` — مفتاح البحث المتساهل (للاستعلام فقط)

مثل `toSearchKey` لكنه يُحوّل **ة → ه** أيضاً. استخدمه على جانب الاستعلام لقبول كلا الشكلين.

```dart
ArabicText.toLooseSearchKey('فاطمة العلي'); // → 'فاطمه العلي'
ArabicText.toLooseSearchKey('فاطمه');       // → 'فاطمه'
// كلاهما ينتج 'فاطمه' — المطابقة ستنجح
```

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

خزّن النص الأصلي ومفتاح البحث في عمودين منفصلين. **لا تستبدل النص الأصلي أبداً.**

```dart
// عند الحفظ في Supabase:
Future<void> saveStudent(String name) async {
  await supabase.from('students').insert({
    'name': name,                               // النص الأصلي للعرض
    'search_key': ArabicText.toSearchKey(name), // مفتاح البحث للاستعلام
  });
}

// عند البحث (مطابقة متساهلة تقبل فاطمة وفاطمه):
Future<List<Map>> searchStudents(String query) async {
  final key = ArabicText.toLooseSearchKey(query);
  return await supabase
      .from('students')
      .select()
      .ilike('search_key', '%$key%');
}
```

```sql
-- إنشاء الجدول:
CREATE TABLE students (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  search_key  text NOT NULL,
  created_at  timestamptz DEFAULT now()
);

CREATE INDEX idx_students_search ON students (search_key text_pattern_ops);
```

---

## مرجع الـ API

| الدالة | الوصف |
|---|---|
| `toSearchKey(text)` | مفتاح بحث للتخزين. يحافظ على ة. |
| `toLooseSearchKey(text)` | مثل toSearchKey + ة→ه. للاستعلام فقط. |
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
| `specVersion` | `'1.0.0'` |

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
