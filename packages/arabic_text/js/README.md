# @devsamhan/arabic-text

مكتبة JavaScript/TypeScript لتطبيع النص العربي — تشكيل، ألفات، همزات، بحث، فرز.

بدون تبعيات خارجية. متوافقة مع [مواصفات devsamhan-arabic v1.0.0](https://github.com/devsamhan/devsamhan-arabic).

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

// مفتاح متساهل للاستعلام (يطابق فاطمة وفاطمه)
toLooseSearchKey('فاطمة');    // → 'فاطمه'
toLooseSearchKey('فاطمه');    // → 'فاطمه'  ← تطابق!

// slug لـ URL
toSlug('مدينة الرياض');       // → 'مدينه-الرياض'

// ترتيب قائمة
sort(['يوسف', 'أحمد', 'محمد']); // → ['أحمد', 'محمد', 'يوسف']

// تحويل الأرقام
normalizeDigits('١٢٣', 'western'); // → '123'
normalizeDigits('123', 'eastern'); // → '١٢٣'
```

---

## الـ API

| الدالة | الوصف |
|---|---|
| `toSearchKey(text)` | مفتاح بحث للتخزين. يحافظ على ة. |
| `toLooseSearchKey(text)` | مثل toSearchKey + ة→ه. للاستعلام فقط. |
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
| `specVersion` | `'1.0.0'` |

---

## نمط قاعدة البيانات

```typescript
// عند الحفظ:
await db.insert({ name, search_key: toSearchKey(name) });

// عند البحث (مطابقة متساهلة):
const key = toLooseSearchKey(query);
await db.select().where('search_key', 'like', `%${key}%`);
```

---

## الترخيص

MIT — [Devsamhan](https://github.com/devsamhan)
