# arabic_bidi

مساعد عرض النص العربي في الطرفية — ربط الحروف، كشف الاتجاه، تسجيل آمن.

جزء من مجموعة [devsamhan-arabic](https://github.com/devsamhan/devsamhan-arabic).

---

## متى تستخدمها؟

**استخدمها في:**
- أدوات CLI مكتوبة بـ Dart
- سكريبتات التشغيل الآلي
- السجلات (logs) في الطرفية
- أي بيئة يظهر فيها النص العربي كحروف منفصلة

**لا تستخدمها في:**
- تطبيقات Flutter — Flutter يرسم العربية صحيحاً بشكل تلقائي
- تطبيقات الويب والمتصفحات
- أي واجهة مستخدم رسومية

> إذا طبّقت `prepareForTerminal` على نص ستعرضه في Flutter `Text` widget، ستحصل على نص مشوه لأن Flutter سيُطبّق خوارزمية BiDi الخاصة به فوق التحويل.

---

## التثبيت

```yaml
dependencies:
  arabic_bidi: ^1.0.0
```

```dart
import 'package:arabic_bidi/arabic_bidi.dart';
```

---

## الاستخدام

### `reshape` — ربط الحروف

يُطبّق التشكيل السياقي: يصل الحروف ببعضها باستخدام أشكال البداية/الوسط/النهاية/المفردة. **لا يُعيد ترتيب النص.**

```dart
// الحروف تبدو منفصلة في الطرفية → تصبح متصلة بعد reshape
final shaped = ArabicBidi.reshape('محمد');
print(shaped); // الحروف الآن بأشكال العرض الصحيحة
```

**دمج لام-ألف (اختياري):**

```dart
// افتراضي — بدون دمج (أكثر توافقاً مع الخطوط)
ArabicBidi.reshape('السلام');

// مع دمج لام-ألف
ArabicBidi.reshape('السلام',
    options: const ArabicReshapeOptions(useLamAlefLigatures: true));
```

---

### `prepareForTerminal` — الإعداد الكامل للطرفية

يُعيد تشكيل النص وعكس ترتيب الكتل عند الحاجة. هذه هي الدالة الرئيسية للاستخدام العملي.

```dart
import 'package:arabic_bidi/arabic_bidi.dart';

void main() {
  final lines = [
    'السلام عليكم',
    'Error في الملف',
    'تم حفظ file.txt بنجاح',
    'الطلب رقم 123',
  ];

  for (final line in lines) {
    print(ArabicBidi.prepareForTerminal(line));
  }
}
```

**نص مختلط عربي/لاتيني:** عندما لا تريد عكس الترتيب (مثل سطور السجل التي تحتوي على رموز خطأ ثابتة):

```dart
// افتراضي — يعكس الترتيب عند أغلبية العربية
ArabicBidi.prepareForTerminal('ملف 123 محفوظ');

// بدون عكس الترتيب
ArabicBidi.prepareForTerminal(
  'Error في الملف',
  options: const ArabicTerminalOptions(reorder: false),
);
```

---

### `detectDirection` — كشف اتجاه النص

يُعيد `Direction.rtl` أو `Direction.ltr` أو `Direction.mixed`.

- **rtl** — عندما تكون ≥ 80% من الحروف عربية
- **ltr** — عندما تكون ≥ 80% من الحروف لاتينية
- **mixed** — عندما لا يصل أي منهما إلى 80%

```dart
ArabicBidi.detectDirection('السلام عليكم');     // Direction.rtl
ArabicBidi.detectDirection('Hello World');       // Direction.ltr
ArabicBidi.detectDirection('Error في الملف');   // Direction.mixed

ArabicBidi.isRTL('مرحبا'); // true
```

---

### `wrapForTerminal` — لفّ النص

يلفّ النص عند حدود الكلمات بحيث لا يتجاوز عرض الطرفية.

```dart
final text = 'هذا نص طويل يحتاج إلى تقطيع عند عرض معين في الطرفية';
final wrapped = ArabicBidi.wrapForTerminal(text, width: 30);
print(ArabicBidi.prepareForTerminal(wrapped));
```

---

### `ArabicLogger` — مسجّل عربي للـ CLI

يُطبّق `prepareForTerminal` تلقائياً على كل رسالة. تنسيق الإخراج: `[timestamp?][prefix?][LEVEL] message`

```dart
import 'package:arabic_bidi/arabic_bidi.dart';

void main() {
  // المتغير الجاهز (بدون بادئة أو توقيت):
  arabicLogger.info('تم التشغيل بنجاح');
  arabicLogger.warn('تحذير: الذاكرة ممتلئة');
  arabicLogger.error('فشل الاتصال بقاعدة البيانات');
  arabicLogger.debug('رسالة تشخيصية');

  // مع بادئة:
  final log = ArabicLogger(prefix: 'قاعدة البيانات');
  log.info('تم الاتصال');
  // الإخراج: [قاعدة البيانات][INFO] <النص>

  // مع توقيت ISO-8601:
  final timedLog = ArabicLogger(useTimestamp: true, prefix: 'نظام');
  timedLog.info('بدأ التطبيق');
  // الإخراج: [2026-05-12 14:30:00][نظام][INFO] <النص>
}
```

---

## القيود المعروفة

> **تحذير:** `arabic_bidi` ليست تطبيقاً كاملاً لخوارزمية Unicode BiDi (UAX #9).

| القيد | التفاصيل |
|---|---|
| إعادة الترتيب | على مستوى الكتل (run-level)، وليس على مستوى الفقرات (paragraph-level) |
| `getVisualOrder` | غير مُنفَّذة — تُعيد النص دون تغيير |
| علامات الترقيم | قد لا تُعرض صحيحاً بجانب النص العربي |
| النص المختلط | استخدم `reorder: false` إذا كان الجزء اللاتيني يجب أن يبقى في مكانه |
| الخطوط | النتائج تختلف باختلاف محاكي الطرفية والخط المستخدم |

**الطرفيات المدعومة:** Windows Terminal، xterm، iTerm2، وأي طرفية تدعم Unicode وخطوط عربية.

**الطرفيات غير المدعومة:** الطرفيات القديمة التي لا تدعم Unicode، والـ CMD القديم بدون خط عربي.

---

## مرجع ربط الحروف

| النوع | يتصل يميناً | يتصل يساراً | أمثلة |
|---|---|---|---|
| D (ثنائي) | ✓ | ✓ | ب ت ث ج ح س ش ص ع ف ق ك ل م ن ه ي |
| R (يميني) | ✗ | ✓ | ا د ذ ر ز و ى |
| U (منفصل) | ✗ | ✗ | ء |
| شفاف | — | — | التشكيل، التطويل |

---

## الترخيص

MIT — [Devsamhan](https://github.com/devsamhan)
