# مكتبات DevSamhan العربية

**مجموعة مكتبات مفتوحة المصدر لتطوير تطبيقات تتعامل مع اللغة العربية بصورة أكثر اتساقاً.** تساعد المطور على تطبيع النصوص، وبناء مفاتيح البحث، والتعامل مع الأرقام العربية، وتحسين عرض العربية في الطرفية، وإنشاء واجهات Flutter عربية، وتجهيز النصوص بعد استخراجها.

[موقع المشروع](https://devsamhan.com/arabic-libraries) · [دليل الاستخدام العربي](docs/arabic_guide.md) · [الأمثلة](examples/) · [المساهمة](CONTRIBUTING.md) · [الترخيص](#الترخيص)

> **تحديث 2 نوفمبر 2026:** نُشر الإصدار **`arabic_text 1.1.0` في Dart وTypeScript وPython** على pub.dev وnpm وPyPI، واكتمل التحقق الفني المستقل من الحزم الثلاث وفق `SPEC_VERSION=1.0.1`. لا ينطبق رقم `1.1.0` على بقية مكتبات المستودع؛ فلها إصدارات ومسارات مستقلة.

## المكتبات المتاحة

| المكتبة | ماذا تقدم؟ | المنصات والتوثيق |
|---|---|---|
| [`arabic_text`](packages/arabic_text/) | تطبيع العربية، مفاتيح البحث، الأرقام، الروابط والترتيب | [Dart / pub.dev](https://pub.dev/packages/arabic_text) · [TypeScript / npm](https://www.npmjs.com/package/@devsamhan/arabic-text) · [Python / PyPI](https://pypi.org/project/devsamhan-arabic-text/) |
| [`arabic_bidi`](packages/arabic_bidi/) | تجهيز العربية للعرض في بيئات الطرفية وأدوات سطر الأوامر | [Dart / pub.dev](https://pub.dev/packages/arabic_bidi) · [TypeScript / npm](https://www.npmjs.com/package/@devsamhan/arabic-bidi) · [Python / PyPI](https://pypi.org/project/devsamhan-arabic-bidi/) |
| [`flutter_arabic_ui`](packages/flutter_arabic_ui/) | حقول نص وبحث وأرقام ومتحققات جاهزة لواجهات Flutter العربية | [Flutter / pub.dev](https://pub.dev/packages/flutter_arabic_ui) |
| [`arabic_devtools`](packages/arabic_devtools/) | أدوات سطر أوامر لفحص النصوص العربية والمشكلات الشائعة أثناء التطوير | [TypeScript / npm](https://www.npmjs.com/package/@devsamhan/arabic-devtools) |
| [`arabic_text_pipeline`](packages/arabic_text_pipeline/) | معالجة النص العربي وتقييمه **بعد** استخراجه من OCR/PDF | [Python / PyPI](https://pypi.org/project/devsamhan-arabic-text-pipeline/) — مرحلة Alpha |

كل مكتبة مستقلة؛ لا يلزم تثبيت المجموعة كاملة. `arabic_bidi` ليست تنفيذاً كاملاً لخوارزمية Unicode Bidirectional Algorithm، و`arabic_text_pipeline` لا تُشغّل OCR ولا تستخرج ملفات PDF بنفسها.

## ما الجديد في `arabic_text 1.1.0`؟

- **تطابق السلوك بين Dart وTypeScript وPython:** 132 حالة مرجعية مشتركة، و2,002 مقارنة عبر اللغات دون اختلاف في التحقق المعتمد للإصدار.
- **تصحيح تحويل الأرقام الفارسية إلى الأرقام العربية الشرقية:** `۱۲۳` تصبح `١٢٣` عند اختيار `eastern` صراحةً.
- **توضيح وضع البحث الصحيح:** مفاتيح صارمة مع مفاتيح صارمة، أو مفاتيح متساهلة مع مفاتيح متساهلة؛ لا تخلط النوعين.
- **تحسين الاعتمادية:** اختبارات التوافق والتعبئة والأمان وGitHub Actions، دون إضافة تبعيات تشغيل لمكتبة `arabic_text`.
- **تحديث التوثيق:** أمثلة أوضح للحفاظ على النص الأصلي، والاستعلامات الفارغة، وأحرف `%` و`_` و`\` في عمليات `LIKE`.

رقم المكتبة **`1.1.0`** يختلف عن رقم العقد السلوكي **`SPEC_VERSION=1.0.1`**. والرقم الثاني توضيح للمواصفة، لا API جديدة.

## البداية السريعة

### Dart / Flutter

```yaml
dependencies:
  arabic_text: ^1.1.0
```

```dart
import 'package:arabic_text/arabic_text.dart';

final original = 'فاطمة';
final strictKey = ArabicText.toSearchKey(original);       // فاطمة
final looseKey = ArabicText.toLooseSearchKey(original);  // فاطمه

ArabicText.toSearchKey('مُحَمَّدٌ'); // محمد
ArabicText.normalizeDigits('۱۲۳', to: 'eastern'); // ١٢٣
```

### JavaScript / TypeScript

```bash
npm install @devsamhan/arabic-text@1.1.0
```

```typescript
import { toSearchKey, toLooseSearchKey, normalizeDigits } from '@devsamhan/arabic-text';

const original = 'فاطمة';
const strictKey = toSearchKey(original);       // فاطمة
const looseKey = toLooseSearchKey(original);  // فاطمه
normalizeDigits('۱۲۳', 'eastern');             // ١٢٣
```

### Python

```bash
pip install devsamhan-arabic-text==1.1.0
```

```python
from devsamhan_arabic_text import to_search_key, to_loose_search_key, normalize_digits

original = 'فاطمة'
strict_key = to_search_key(original)        # فاطمة
loose_key = to_loose_search_key(original)   # فاطمه
normalize_digits('۱۲۳', 'eastern')          # ١٢٣
```

> **حالة Python:** الإصدار `1.1.0` منشور على [PyPI](https://pypi.org/project/devsamhan-arabic-text/1.1.0/) بملفي Wheel وsdist، وقد اجتاز كل منهما 132 حالة مرجعية عند التثبيت من السجل العام وفق أدلة الإصدار.

## كيف تتعامل مع البحث في قاعدة البيانات؟

**احفظ الاسم الأصلي كما أدخله المستخدم**، واحسب مفاتيح البحث في أعمدة مشتقة. المثال التالي يوضح الفكرة فقط ولا ينفّذ عملية ترحيل قاعدة البيانات:

| القيمة | الناتج |
|---|---|
| النص الأصلي | `فاطمة` |
| `toSearchKey('فاطمة')` | `فاطمة` — صارم |
| `toLooseSearchKey('فاطمة')` | `فاطمه` — متساهل |
| `toLooseSearchKey('فاطمه')` | `فاطمه` — متساهل |

**صحيح:** قارن `toSearchKey(query)` بعمود `search_key` المحسوب بالدالة نفسها. وللبحث المتساهل، قارن `toLooseSearchKey(query)` بعمود `search_key_loose` المحسوب بالدالة نفسها.

**خطأ:** حساب `search_key` بالدالة الصارمة ثم البحث فيه باستخدام مفتاح متساهل؛ سيؤدي إلى نتائج ناقصة، خصوصاً مع `ة/ه`.

وللبحث باستخدام SQL، اربط القيم بالمعاملات بدلاً من تركيب النص داخل الاستعلام، وتعامل مع `%` و`_` و`\` بوصفها أحرفاً خاصة في `LIKE`. لا ترسل نمط `%%` عند إدخال استعلام فارغ. راجع [دليل البحث والتخزين](docs/arabic_guide.md) و[مواصفة السلوك](test_fixtures/SPEC.md) قبل تنفيذ الترحيل أو إعادة الفهرسة.

> **تنبيه للترقية:** إن كانت تطبيقاتك قد خزّنت نواتج تحويل الأرقام الفارسية من نسخ سابقة، فقد تحتاج إلى تحديث المفاتيح المشتقة أو إعادة فهرستها بعد مراجعة بياناتك. لا تغيّر النص الأصلي بصمت.

## باقي المكتبات: أمثلة سريعة

### `arabic_bidi` للطرفية

```yaml
dependencies:
  arabic_bidi: ^1.0.0
```

```dart
import 'package:arabic_bidi/arabic_bidi.dart';

final prepared = ArabicBidi.prepareForTerminal('السلام عليكم');
final logger = ArabicLogger(prefix: 'تطبيقي');
logger.info('تم التشغيل بنجاح');
```

هذه المكتبة مخصصة للبيئات التي لا تعرض العربية جيداً؛ لا تستخدمها لإعادة ترتيب النص في Flutter أو الويب حيث يتولى محرك العرض معالجة اتجاه النص.

### `flutter_arabic_ui` لواجهات Flutter

```yaml
dependencies:
  flutter_arabic_ui: ^1.0.0
```

```dart
import 'package:flutter_arabic_ui/flutter_arabic_ui.dart';

ArabicTextField(
  decoration: const InputDecoration(labelText: 'الاسم'),
);
```

تجد أمثلة بقية المكوّنات وأدوات CLI والمعالجة بعد الاستخراج داخل مجلدات المكتبات وتوثيق المشروع.

## التوثيق والأمثلة

- [الدليل العربي](docs/arabic_guide.md) — وظائف المكتبات وأمثلة الاستخدام.
- [مواصفة السلوك `SPEC_VERSION=1.0.1`](test_fixtures/SPEC.md) — المرجع المشترك للغات الثلاث.
- [أمثلة Dart](examples/dart/) · [أمثلة TypeScript](examples/js/) · [أمثلة Python](examples/python/).
- [إرشادات المساهمة](CONTRIBUTING.md) — الاختبارات ومراجعة التغييرات.
- [سجل الإصدارات](RELEASE_NOTES.md) — التاريخ العام للمكتبات.
- [حالة إصدار 1.1.0 والخطوات القادمة](docs/arabic_text_1_1_0_status_ar.md).

## كيف نتحقق من الجودة؟

تتبع منافذ `arabic_text` مواصفة وملفات fixtures مشتركة. تشمل اختبارات الإصدار المقبولة **30 اختباراً في Dart و144 اختباراً في TypeScript و144 اختباراً في Python و18 اختباراً لأداة المقارنة**، إلى جانب المقارنة المرجعية عبر اللغات. نجحت وظائف `dart` و`typescript` و`python` و`parity` في GitHub Actions على مصدر الإصدار المدمج.

هذه النتائج لا تعني أن كل تكامل خارجي قد اختُبر؛ تكاملات SDK المستضافة وCloudflare Worker لها نطاق تحقق مستقل.

[عرض تشغيل GitHub Actions بعد الدمج](https://github.com/devsamhan/devsamhan-arabic/actions/runs/41291944543) · [نسخة المصدر الموسومة 1.1.0](https://github.com/devsamhan/devsamhan-arabic/tree/arabic_text-v1.1.0)

## المساهمة

المساهمات مرحب بها. ابدأ بقراءة [CONTRIBUTING.md](CONTRIBUTING.md) والمواصفة المشتركة. إذا غيّرت سلوك تطبيع، فأضف حالة اختبار مشتركة أولاً، ثم طبّق السلوك نفسه في المنافذ المعنية. يمكنك الإبلاغ عن مشكلة أو اقتراح تحسين عبر [GitHub Issues](https://github.com/devsamhan/devsamhan-arabic/issues).

## الترخيص

MIT — [Devsamhan](https://github.com/devsamhan).
