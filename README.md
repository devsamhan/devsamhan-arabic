# مكتبات Devsamhan العربية

مكتبات مفتوحة المصدر لسد الفجوة في دعم اللغة العربية برمجياً.

---

## المكتبات

| المكتبة | الوصف | pub.dev |
|---|---|---|
| [`arabic_text`](packages/arabic_text/dart/) | تطبيع النص العربي — بحث، فرز، أسماء، slug | [![pub.dev](https://img.shields.io/pub/v/arabic_text.svg)](https://pub.dev/packages/arabic_text) |
| [`arabic_bidi`](packages/arabic_bidi/dart/) | عرض العربية في الطرفية — ربط الحروف، logger، كشف الاتجاه | [![pub.dev](https://img.shields.io/pub/v/arabic_bidi.svg)](https://pub.dev/packages/arabic_bidi) |
| [`flutter_arabic_ui`](packages/flutter_arabic_ui/) | مكوّنات Flutter العربية — حقول، formatters، controllers، validators | [![pub.dev](https://img.shields.io/pub/v/flutter_arabic_ui.svg)](https://pub.dev/packages/flutter_arabic_ui) |

---

## البداية السريعة

### arabic_text

```yaml
dependencies:
  arabic_text: ^1.0.0
```

```dart
import 'package:arabic_text/arabic_text.dart';

// مفتاح بحث للتخزين في قاعدة البيانات
ArabicText.toSearchKey('مُحَمَّدٌ');          // → 'محمد'
ArabicText.toSearchKey('فاطمة العلي');       // → 'فاطمة العلي'

// مفتاح متساهل للاستعلام (يطابق فاطمة وفاطمه)
ArabicText.toLooseSearchKey('فاطمه');        // → 'فاطمه'
ArabicText.toLooseSearchKey('فاطمة');        // → 'فاطمه' ← تطابق!

// slug لـ URL
ArabicText.toSlug('مدينة الرياض');           // → 'مدينه-الرياض'

// ترتيب قائمة
ArabicText.sort(['يوسف', 'أحمد', 'محمد']);  // → ['احمد', 'محمد', 'يوسف']
```

### arabic_bidi (CLI فقط)

```yaml
dependencies:
  arabic_bidi: ^1.0.0
```

```dart
import 'package:arabic_bidi/arabic_bidi.dart';

// إعداد النص للطرفية
ArabicBidi.prepareForTerminal('السلام عليكم');

// مسجّل عربي
final log = ArabicLogger(prefix: 'تطبيقي');
log.info('تم التشغيل بنجاح');
log.error('فشل الاتصال');
```

### flutter_arabic_ui

```yaml
dependencies:
  flutter_arabic_ui: ^1.0.0
```

```dart
import 'package:flutter_arabic_ui/flutter_arabic_ui.dart';

// حقل نص عربي مع RTL تلقائي
ArabicTextField(
  decoration: const InputDecoration(labelText: 'الاسم'),
)

// حقل بحث مع مفتاح بحث تلقائي
ArabicSearchField(
  onSearchKeyChanged: (key) => _filter(key),
)

// حقل أرقام مع تحويل تلقائي
ArabicNumberField(
  digitDirection: ArabicDigitDirection.western,
  onNormalizedChanged: (digits) => _process(digits),
)

// التحقق من صحة الحقول
TextFormField(
  validator: ArabicValidators.requiredArabic,
)
```

---

## التوثيق

[docs/arabic_guide.md](docs/arabic_guide.md) — دليل شامل بالعربية يشمل جميع الدوال والأنماط والأسئلة الشائعة.

---

## هيكل المشروع

```
packages/
  arabic_text/dart/       — مكتبة Dart بدون تبعيات
  arabic_bidi/dart/       — مساعد الطرفية
  flutter_arabic_ui/      — مكوّنات Flutter
test_app/                 — تطبيق اختبار يستخدم جميع المكتبات
docs/
  arabic_guide.md         — الدليل الشامل
```

---

## المساهمة

اقرأ [SPEC.md](https://github.com/devsamhan/devsamhan-arabic/blob/master/claude/SPEC.md) أولاً — يحدد العقد السلوكي الذي يجب أن تلتزم به جميع المنافذ (Dart، TypeScript، Python).

أي تغيير في سلوك دالة يتطلب تحديثاً في `test_fixtures/` أولاً.

---

## الترخيص

MIT — [Devsamhan](https://github.com/devsamhan)
