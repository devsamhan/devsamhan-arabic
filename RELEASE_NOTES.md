# ملاحظات الإصدار — devsamhan-arabic

---

## v1.0.0 — الإصدار الأول

### المكتبات المنشورة

**arabic_text**
- Dart على [pub.dev](https://pub.dev/packages/arabic_text)
- TypeScript على [npm](https://www.npmjs.com/package/@devsamhan/arabic-text)
- Python على [PyPI](https://pypi.org/project/devsamhan-arabic-text/)

**arabic_bidi**
- Dart على [pub.dev](https://pub.dev/packages/arabic_bidi)
- TypeScript على [npm](https://www.npmjs.com/package/@devsamhan/arabic-bidi)
- Python على [PyPI](https://pypi.org/project/devsamhan-arabic-bidi/)

**flutter_arabic_ui**
- Flutter/Dart على [pub.dev](https://pub.dev/packages/flutter_arabic_ui)

---

### ما تضمّنه هذا الإصدار

**توحيد السلوك**
- جميع المنافذ (Dart، TypeScript، Python) تخضع لنفس `test_fixtures/` — السلوك موحّد عبر المنصات الثلاث.

**arabic_text — التطبيع والبحث**
- تطبيع التشكيل (تشكيل، تطويل، همزات، يا).
- مفاتيح بحث دقيقة (`toSearchKey`) ومتساهلة (`toLooseSearchKey`).
- توليد slug عربي للـ URL.
- فرز بسيط قائم على مفاتيح مُطبَّعة.
- دعم الأرقام العربية الشرقية والفارسية.

**arabic_bidi — الطرفية والـ CLI**
- إعادة تشكيل الحروف العربية لعرضها صحيحاً في الطرفية (Presentation Forms-B).
- إعادة ترتيب المقاطع للنص المختلط (عربي + لاتيني).
- كشف اتجاه النص (RTL / LTR / MIXED).
- مسجّل عربي (`ArabicLogger`) مع دعم prefix والطابع الزمني.
- خوارزمية تحديد الأغلبية: نسبة الحروف العربية فقط (U+0621–U+063A، U+0641–U+064A) مقسومةً على المحارف غير المسافة، عتبة > 0.5.

**flutter_arabic_ui — مكوّنات Flutter**
- `ArabicTextField`: حقل نص مع RTL تلقائي.
- `ArabicSearchField`: حقل بحث مع مفتاح بحث تلقائي.
- `ArabicNumberField`: حقل أرقام مع تحويل تلقائي.
- `ArabicValidators`: validators للحقول العربية.

---

### ملاحظات تقنية

- `arabic_bidi` يطبق خوارزمية BiDi مبسّطة مصمَّمة للـ CLI والـ logs — ليست بديلاً لـ ICU أو UAX #9 الكامل.
- جميع المكتبات بدون تبعيات خارجية في وقت التشغيل (arabic_bidi لا يعتمد على arabic_text).
- اصطلاح التسمية: camelCase في Dart وTypeScript، snake_case في Python.
