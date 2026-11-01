# دليل مكتبات devsamhan-arabic

---

## 1. مقدمة

تُعالج هذه المكتبات مشكلةً تُواجه كل مطوّر يبني تطبيقاً بالعربية: الحرف العربي الواحد يكتبه المستخدمون بأشكال متعددة. كلمة «فاطمة» قد تُكتب «فاطمه» أو «فاطمﺔ» أو «فاطِمَة» — وكلها تعني الشيء ذاته، لكن المقارنة الحرفية ستُخفق مع كل اختلاف.

المكتبات الثلاث تحل هذه المشكلة على مستويات مختلفة:

| المكتبة | المشكلة التي تحلّها | البيئة |
|---|---|---|
| `arabic_text` | توحيد النص العربي وفهرسته | Dart + Flutter |
| `arabic_bidi` | عرض العربية صحيحاً في الطرفية | CLI / سكريبت |
| `flutter_arabic_ui` | حقول إدخال وتحقق جاهزة للاستخدام | Flutter فقط |

المكتبات الثلاث مبنية على **عقد سلوكي مشترك** موثق في `SPEC.md`. هذا يعني أن أي وظيفة موجودة في المكتبة تتصرف بالطريقة نفسها بغض النظر عن اللغة أو المنصة، وأن نتائج `toSearchKey` في Dart ستكون متطابقة مع نتائجها في TypeScript أو Python عند نشر المنافذ لاحقاً.

---

## 2. arabic_text

### ما هي وظيفتها

`arabic_text` هي مكتبة Dart بدون تبعيات خارجية تُوحّد النص العربي. تُزيل التشكيل والتطويل، وتُعيد الحروف المتعددة إلى شكلها القياسي، وتُنتج مفاتيح بحث وفرز موثوقة.

### متى تحتاجها

- عند تخزين أسماء أو نصوص في قاعدة بيانات وتريد البحث فيها بصرف النظر عن طريقة كتابة المستخدم
- عند مقارنة نصين وتريد تجاهل الفوارق الإملائية
- عند ترتيب قائمة عربية ترتيباً ثابتاً
- عند بناء روابط URL تحتوي على نص عربي

### تثبيت المكتبة

```yaml
# pubspec.yaml
dependencies:
  arabic_text: ^1.0.0
```

```dart
import 'package:arabic_text/arabic_text.dart';
```

---

### الدوال التفصيلية

#### `removeTashkeel`

تُزيل جميع علامات الشكل (فتحة، ضمة، كسرة، تنوين، شدة، سكون) وعلامات الضبط القرآني.

```dart
void main() {
  final input = 'مُحَمَّد';
  final result = ArabicText.removeTashkeel(input);
  print(result); // محمد
}
```

> **متى تستخدمها:** قبل تخزين الأسماء في قاعدة البيانات، أو قبل المقارنة بين نصين حيث أحدهما قد يكون مشكولاً.

---

#### `normalizeAlef`

تُحوّل جميع أشكال الألف المتعددة (أ، إ، آ، ٱ) إلى ألف مجردة (ا).

```dart
void main() {
  print(ArabicText.normalizeAlef('أحمد'));   // احمد
  print(ArabicText.normalizeAlef('إبراهيم')); // ابراهيم
  print(ArabicText.normalizeAlef('آمنة'));   // امنة
}
```

> **تحذير:** لا تستخدم هذه الدالة منفردةً للأسماء المخزّنة. استخدم `normalizeName` بدلاً منها — فهي تُطبّق الخطوات الصحيحة بترتيبها المحدد في SPEC.md.

---

#### `toSearchKey`

تُنتج مفتاح بحث مُعياراً مناسباً لتخزينه في قاعدة البيانات وللاستعلام عنه. تُطبّق: تطبيع أشكال العرض، إزالة التطويل، إزالة التشكيل، توحيد الألف، الهمزة، الياء، وطيّ المسافات. **تحافظ على التاء المربوطة (ة) دون تغيير.**

```dart
void main() {
  // بحث عن اسم: المستخدم يكتب بطريقته والمخزن بطريقة أخرى
  final stored = ArabicText.toSearchKey('فاطمة العلي');
  // النتيجة: 'فاطمة العلي' (بعد إزالة التشكيل وتوحيد الألف)

  final query = ArabicText.toSearchKey('فاطمه');
  // النتيجة: 'فاطمه' — لن تُطابق 'فاطمة' لأن ة ≠ ه

  print(stored == query); // false — استخدم toLooseSearchKey للمطابقة
}
```

**نمط قاعدة البيانات الصحيح:**

خزّن النص الأصلي للعرض، ومفتاحاً صارماً للبحث الصارم، وعموداً متساهلاً **اختيارياً** للبحث المتساهل. لا تستبدل النص الأصلي أبداً، ولا تغيّر `search_key` القائم.

```dart
// عند الحفظ في Supabase أو أي قاعدة بيانات:
Future<void> saveStudent(String name) async {
  await supabase.from('students').insert({
    'name': name,                                          // النص الأصلي للعرض
    'search_key': ArabicText.toSearchKey(name),            // صارم
    'search_key_loose': ArabicText.toLooseSearchKey(name), // اختياري للمطابقة المتساهلة
  });
}

String escapeLike(String value) => value
    .replaceAll(r'\', r'\\')
    .replaceAll('%', r'\%')
    .replaceAll('_', r'\_');

// البحث الحرفي: صارم/صارم أو متساهل/متساهل.
Future<List<Map>> searchStudents(String query, {required bool loose}) async {
  final key = loose
      ? ArabicText.toLooseSearchKey(query.trim())
      : ArabicText.toSearchKey(query.trim());
  if (key.isEmpty) return const [];
  final pattern = '%${escapeLike(key)}%';
  final column = loose ? 'search_key_loose' : 'search_key';
  return await supabase.from('students').select().like(column, pattern);
}
```

اختبرنا **HTTP مباشراً** إلى `.like()` محلياً مع **PostgREST 14.10 + PostgreSQL 16**: النمط `*100\%*` طابق `100%` حرفياً فقط، و`*a\_b*` طابق `a_b` حرفياً فقط، و`*back\\slash*` طابق `back\slash` حرفياً. لم تُختبر استدعاءات Supabase SDK أو الخدمة المستضافة؛ أعد اختبار إصدارك إذا اختلف.

```sql
ALTER TABLE students ADD COLUMN IF NOT EXISTS search_key_loose text;
UPDATE students SET search_key_loose = replace(search_key, 'ة', 'ه')
WHERE search_key IS NOT NULL AND search_key_loose IS NULL;

-- للبحث بالبادئة فقط:
CREATE INDEX IF NOT EXISTS idx_students_loose_prefix
  ON students (search_key_loose text_pattern_ops);
-- للاحتواء %query% استخدم pg_trgm وليس text_pattern_ops.
```

> **تحذير:** `toSearchKey('فاطمة')` ينتج `فاطمة`، و`toLooseSearchKey('فاطمه')` ينتج `فاطمه`. مقارنة الاثنين تُرجع `false`؛ استخدم صارم/صارم أو متساهل/متساهل. لا ترسل استعلاماً فارغاً كـ `%%`. حالة تكامل PostgreSQL/Supabase **UNVERIFIED** في هذا المستودع؛ الأمثلة تتبع توثيق PostgreSQL ولا تدّعي اختباراً حياً.

---

#### `toLooseSearchKey`

مثل `toSearchKey` تماماً، لكنها **تُحوّل التاء المربوطة (ة) إلى هاء (ه)** أيضاً.

**الفرق العملي بين `toSearchKey` و `toLooseSearchKey`:**

| الحالة | `toSearchKey('فاطمة')` | `toLooseSearchKey('فاطمة')` |
|---|---|---|
| النتيجة | `فاطمة` | `فاطمه` |

المشكلة التي تحلّها:

```dart
void main() {
  final stored = 'فاطمة العلي'; // كما هو في قاعدة البيانات
  final userTyped = 'فاطمه';   // المستخدم كتب هاء عادية

  // ❌ مطابقة صارمة — ستفشل
  final strictStored = ArabicText.toSearchKey(stored); // فاطمة العلي
  final strictQuery  = ArabicText.toSearchKey(userTyped); // فاطمه
  print(strictStored.contains(strictQuery)); // false

  // ✅ مطابقة متساهلة — ستنجح
  final looseStored = ArabicText.toLooseSearchKey(stored); // فاطمه العلي
  final looseQuery  = ArabicText.toLooseSearchKey(userTyped); // فاطمه
  print(looseStored.contains(looseQuery)); // true
}
```

**قاعدة الاستخدام:** طبّق `toLooseSearchKey` على **الطرفين** — الاستعلام وكل عنصر في القائمة — أو لا تستخدمه على أي منهما. الخلط بين النوعين يُفسد النتائج.

---

#### `toDisplayKey`

تُنظّف النص للعرض: تُزيل التطويل فقط، وتطوي المسافات المتكررة. تحافظ على التشكيل والهمزة وجميع الأحرف الأخرى.

```dart
void main() {
  final messy = 'مـحـمـد  الأحـمـد'; // تطويل وفراغات متكررة
  print(ArabicText.toDisplayKey(messy)); // محمد الأحمد
}
```

> **استخدامها:** في واجهة المستخدم عندما تريد تنظيف ما يكتبه المستخدم للعرض دون فقدان أي معلومات لغوية.

---

#### `toSlug`

تُنتج معرّفاً آمناً لـ URL يحتوي على أحرف عربية يونيكود (وليس تحويلاً حرفياً إلى لاتينية). تُطبّق كل خطوات `toSearchKey` ثم تُحوّل ة→ه، وتستبدل المسافات بـ `-`، وتُزيل الرموز الخاصة.

```dart
void main() {
  final name = 'محمد الأحمد';
  print(ArabicText.toSlug(name)); // محمد-الاحمد

  final title = 'مقالة: أبرز الأحداث في ٢٠٢٤';
  print(ArabicText.toSlug(title)); // مقاله-ابرز-الاحداث-في-٢٠٢٤
}
```

> **ملاحظة:** الأرقام العربية (١٢٣) تبقى كما هي في المخرج لأن `toSlug` لا يُحوّل الأرقام. إذا أردت أرقاماً غربية استدع `normalizeDigits` قبل `toSlug`.

---

#### `normalizeName`

تُعيّر الأسماء الشخصية للمطابقة وإلغاء التكرار. تُطبّق: تطبيع أشكال العرض، التطويل، التشكيل، الألف، الهمزة، الياء الفارسية. **لا تُحوّل ى → ي** (ألف مقصورة ذات قيمة لغوية في الأسماء) **ولا تُحوّل ة → ه**.

```dart
void main() {
  final names = [
    'محمد',
    'مُحَمَّد',      // مشكول
    'مـحـمـد',      // مع تطويل
    'Mohammed',     // لاتيني — لا يتأثر
  ];

  for (final n in names) {
    print('${n.padRight(15)} → ${ArabicText.normalizeName(n)}');
  }
  // محمد           → محمد
  // مُحَمَّد         → محمد
  // مـحـمـد         → محمد
  // Mohammed       → Mohammed
}
```

---

#### `sort` و `compare`

ترتيب قائمة عربية ترتيباً ثابتاً بناءً على مفاتيح التطبيع.

```dart
void main() {
  final cities = ['الرياض', 'أبوظبي', 'القاهرة', 'بيروت', 'دبي'];

  final sorted = ArabicText.sort(cities);
  print(sorted);
  // [ابوظبي، الرياض، القاهرة، بيروت، دبي]
  // (الألف تُعادَل بعد إزالة الهمزة)

  // مقارنة مفردة للفرز اليدوي:
  final items = ['نُورَة', 'أحمد', 'فاطمة'];
  items.sort(ArabicText.compare);
  print(items); // [احمد، فاطمة، نورة]
}
```

> **تحذير:** هذا ترتيب معجمي يونيكود بعد التطبيع، وليس ترتيباً قاموسياً عربياً كاملاً. ال (التعريف) لا يُحذف من الترتيب، و ة/ه تُرتَّبان بشكل منفصل. لا تُعلن أنه «ترتيب أبجدي عربي». دعم `ArabicCollator` الكامل مقرر في إصدار مستقبلي.

---

## 3. arabic_bidi

### ما هي وظيفتها

`arabic_bidi` تُعالج مشكلة عرض النص العربي في الطرفية (terminal). المحطات اللاتينية تعمل من اليسار إلى اليمين، وكثير منها لا تدعم خوارزمية البيدي (UAX #9) المسؤولة عن عرض النص العربي صحيحاً. النتيجة: النص يظهر مشوهاً أو مقلوباً.

### متى تحتاجها

**تحتاجها فقط في:**
- أدوات CLI مكتوبة بـ Dart
- سكريبتات التشغيل الآلي (automation scripts)
- السجلات (logs) المكتوبة في الطرفية

**لا تحتاجها أبداً في:**
- تطبيقات Flutter — فـ Flutter يرسم النص بنفسه بشكل صحيح
- المتصفحات
- أي واجهة مستخدم رسومية

### تثبيت المكتبة

```yaml
# pubspec.yaml (لتطبيقات CLI فقط، ليس flutter)
dependencies:
  arabic_bidi: ^1.0.0
```

```dart
import 'package:arabic_bidi/arabic_bidi.dart';
```

---

### `reshape`

تُطبّق التشكيل السياقي للحروف العربية: تصل الحروف ببعضها باستخدام أشكال البداية/الوسط/النهاية/المفردة الصحيحة. **لا تُعيد ترتيب النص.**

```dart
void main() {
  final logical = 'محمد'; // الترتيب المنطقي (كما يُخزَّن)
  final visual = ArabicBidi.reshape(logical);
  // النتيجة: أشكال العرض (Presentation Forms-B) — الحروف متصلة
  print(visual);
}
```

---

### `prepareForTerminal`

الدالة الرئيسية للاستخدام العملي. تُعيد تشكيل النص العربي **وتعكس ترتيب الكتل** عند الحاجة، بحيث يظهر النص العربي من اليمين إلى اليسار حتى في طرفية LTR.

```dart
import 'package:arabic_bidi/arabic_bidi.dart';

void main() {
  final lines = [
    'السلام عليكم',
    'Error في الملف',
    'تم حفظ file.txt',
    'الطلب رقم 123',
  ];

  print('=== بدون معالجة ===');
  for (final line in lines) {
    print(line); // قد يظهر مقلوباً في بعض الطرفيات
  }

  print('\n=== مع prepareForTerminal ===');
  for (final line in lines) {
    print(ArabicBidi.prepareForTerminal(line));
  }
}
```

---

### `detectDirection`

تكتشف الاتجاه السائد في النص وتُعيد `Direction.rtl` أو `Direction.ltr` أو `Direction.mixed`.

- `rtl`: حين يكون ≥ 80% من الحروف عربية
- `ltr`: حين يكون ≥ 80% من الحروف لاتينية
- `mixed`: حين لا يصل أي منهما إلى 80%

```dart
void main() {
  final samples = [
    'السلام عليكم',           // عربي بحت
    'Hello World',            // لاتيني بحت
    'Error في الملف',         // مختلط
    'تم حفظ file.txt بنجاح', // مختلط
  ];

  for (final text in samples) {
    final dir = ArabicBidi.detectDirection(text);
    final prepared = ArabicBidi.prepareForTerminal(text);
    print('[$dir] $prepared');
  }
  // [Direction.rtl]   مليكع مالسلا
  // [Direction.ltr]   Hello World
  // [Direction.mixed] ﻒﻠﻤﻟا ﻲﻓ Error
  // [Direction.mixed] ﺎﺤﺠﻧ txt.file ﻆﻔﺣ ﻢﺗ
}
```

---

### `wrapForTerminal`

تلفّ النص عند حدود الكلمات بحيث لا يتجاوز عرض الطرفية.

```dart
void main() {
  final longText = 'هذا نص طويل يحتاج إلى تقطيع عند عرض معين في الطرفية';
  final wrapped = ArabicBidi.wrapForTerminal(longText, width: 30);
  print(ArabicBidi.prepareForTerminal(wrapped));
}
```

---

### `ArabicLogger`

مسجّل (logger) جاهز للاستخدام في أدوات CLI. يُطبّق `prepareForTerminal` على كل رسالة تلقائياً.

تنسيق الإخراج: `[timestamp?][prefix?][LEVEL] message`

```dart
import 'package:arabic_bidi/arabic_bidi.dart';

void main() {
  // أبسط استخدام — بدون بادئة أو توقيت:
  final log = ArabicLogger();
  log.info('تم تحميل الإعدادات');
  log.warn('المستخدم لم يُسجّل دخولاً منذ فترة طويلة');
  log.error('فشل الاتصال بقاعدة البيانات');

  // مع بادئة لتمييز وحدة المشروع:
  final dbLog = ArabicLogger(prefix: 'قاعدة البيانات');
  dbLog.info('تم الاتصال بنجاح');
  // الإخراج: [قاعدة البيانات][INFO] <النص المُعالج>

  // مع توقيت ISO-8601:
  final timedLog = ArabicLogger(useTimestamp: true, prefix: 'نظام');
  timedLog.info('بدأ التطبيق');
  // الإخراج: [2026-05-12 14:30:00][نظام][INFO] <النص المُعالج>

  // المتغير الجاهز (بدون بادئة أو توقيت):
  arabicLogger.debug('رسالة تشخيصية');
}
```

**المستويات المتاحة:** `info`، `warn`، `error`، `debug`

---

### القيود الموثقة

> **تحذير:** `arabic_bidi` **ليست** تطبيقاً كاملاً لخوارزمية Unicode BiDi (UAX #9). القيود الحالية:
>
> - `getVisualOrder` غير مُنفَّذة — تُعيد النص دون تغيير
> - `prepareForTerminal` تعمل بأسلوب «أفضل جهد» (best-effort) ولا تضمن نتائج مثالية مع كل نص مختلط معقد
> - لام-ألف (لا) يُدعم فقط إذا مُرّرت `ArabicReshapeOptions` بتفعيل الدمج
> - مناسبة للطرفيات اللاتينية (xterm، Windows Terminal) — نتائجها تختلف باختلاف محاكي الطرفية

---

## 4. flutter_arabic_ui

### ما هي وظيفتها

`flutter_arabic_ui` توفر مكوّنات Flutter جاهزة مُهيأة للعربية: حقول إدخال مع اتجاه RTL تلقائي، controllers مع دوال مساعدة، ومتحققات (validators) متوافقة مع `Form`.

لا تفرض أي تصميم بصري (ألوان، خطوط، حواف) — كل شيء يمر إلى `TextField` الأصلي كما هو.

### تثبيت المكتبة

```yaml
# pubspec.yaml
dependencies:
  flutter_arabic_ui: ^1.0.0
```

```dart
import 'package:flutter_arabic_ui/flutter_arabic_ui.dart';
```

---

### الـ Widgets

#### `ArabicTextField`

حقل إدخال عربي مع RTL تلقائي. يحافظ على نفس واجهة `TextField` تماماً مع إضافة خيار التطبيع التلقائي.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_arabic_ui/flutter_arabic_ui.dart';

class NameField extends StatefulWidget {
  const NameField({super.key});
  @override
  State<NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<NameField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ArabicTextField(
      controller: _controller,
      decoration: const InputDecoration(
        labelText: 'اسم المستخدم',
        border: OutlineInputBorder(),
      ),
      // autoNormalize: false (الافتراضي) — النص لا يتغير أثناء الكتابة
    );
  }
}
```

**مع التطبيع التلقائي** (يُزيل التشكيل والتطويل عند كل ضغطة):

```dart
ArabicTextField(
  controller: _controller,
  autoNormalize: true,
  normalizeOptions: const ArabicNormalizeOptions(
    removeTashkeel: true,
    removeTatweel: true,
    normalizeAlef: true,
  ),
  decoration: const InputDecoration(
    labelText: 'البحث في السجلات',
    border: OutlineInputBorder(),
  ),
)
```

> **تحذير:** لا تُفعّل `autoNormalize: true` في حقول الأسماء إذا كنت تريد حفظ الاسم بشكله الأصلي. التطبيع التلقائي يُغيّر النص المرئي للمستخدم مباشرةً.

---

#### `ArabicSearchField`

حقل بحث يُولّد مفتاح بحث معياراً في كل تغيير. `onChanged` يُعطيك النص الخام، `onSearchKeyChanged` يُعطيك المفتاح المُعيَّر جاهزاً للاستعلام.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_arabic_ui/flutter_arabic_ui.dart';
import 'package:arabic_text/arabic_text.dart';

class TeacherSearch extends StatefulWidget {
  const TeacherSearch({super.key});
  @override
  State<TeacherSearch> createState() => _TeacherSearchState();
}

class _TeacherSearchState extends State<TeacherSearch> {
  final _teachers = ['فاطمة العلي', 'نورة الشمري', 'أحمد محمد'];
  List<String> _results = [];

  void _onSearchChanged(String raw) {
    final queryKey = ArabicText.toLooseSearchKey(raw);
    setState(() {
      _results = raw.isEmpty
          ? _teachers
          : _teachers
              .where((t) => ArabicText.toLooseSearchKey(t).contains(queryKey))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ArabicSearchField(
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'ابحث عن معلم...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, i) => ListTile(title: Text(_results[i])),
          ),
        ),
      ],
    );
  }
}
```

---

#### `ArabicNumberField`

حقل أرقام يُحوّل أشكال الأرقام تلقائياً. يُفعّل `ArabicNumberFormatter` داخلياً.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_arabic_ui/flutter_arabic_ui.dart';

class PhoneForm extends StatelessWidget {
  final _controller = TextEditingController();

  PhoneForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // حقل هاتف: يقبل أي شكل أرقام ويُحوّلها إلى غربية (0-9)
        ArabicNumberField(
          controller: _controller,
          digitDirection: ArabicDigitDirection.western,
          decoration: const InputDecoration(
            labelText: 'رقم الهاتف',
            hintText: '0501234567',
            border: OutlineInputBorder(),
          ),
          onNormalizedChanged: (westernDigits) {
            // westernDigits دائماً بالأرقام الغربية 0-9
            // آمن للتحويل إلى int/double مباشرة
            print('للمعالجة: $westernDigits');
          },
        ),

        const SizedBox(height: 16),

        // حقل مبالغ: يُحوّل الأرقام الغربية إلى عربية شرقية (٠-٩)
        ArabicNumberField(
          digitDirection: ArabicDigitDirection.eastern,
          decoration: const InputDecoration(
            labelText: 'المبلغ بالأرقام العربية',
            hintText: '١٢٣٤٥',
            border: OutlineInputBorder(),
          ),
          onChanged: (displayValue) {
            print('المعروض: $displayValue'); // ٠-٩
          },
          onNormalizedChanged: (westernDigits) {
            print('للحساب: $westernDigits'); // 0-9 دائماً
          },
        ),
      ],
    );
  }
}
```

---

### الـ Formatters مباشرةً

يمكن استخدام الـ formatters مباشرةً مع أي `TextFormField` أو `TextField` عادي.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_arabic_ui/flutter_arabic_ui.dart';

// ArabicInputFormatter — يُعيّر النص عند كل ضغطة
TextField(
  inputFormatters: const [ArabicInputFormatter()],
  // الافتراضي: يُزيل التشكيل والتطويل فقط
)

// مع خيارات مخصصة:
TextField(
  inputFormatters: [
    ArabicInputFormatter(
      options: const ArabicNormalizeOptions(
        removeTashkeel: true,
        removeTatweel: true,
        normalizeAlef: true,
        normalizeHamza: true,
      ),
    ),
  ],
)

// ArabicNumberFormatter — تحويل الأرقام فقط
TextField(
  inputFormatters: [
    const ArabicNumberFormatter(direction: ArabicDigitDirection.eastern),
  ],
)

// ArabicSearchKeyFormatter — يُطبّق toSearchKey على النص المرئي
// (استخدمه داخل ArabicSearchField، ليس في حقول الإدخال العادية)
TextField(
  inputFormatters: const [ArabicSearchKeyFormatter()],
)
```

---

### الـ Controllers

#### `ArabicTextEditingController`

يمتد `TextEditingController` ويُضيف getters مفيدة. **النص لا يتغير تلقائياً أبداً** — الـ getters للقراءة فقط.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_arabic_ui/flutter_arabic_ui.dart';

class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key});
  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _nameController = ArabicTextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSave() {
    final original = _nameController.text;
    final searchKey = _nameController.searchKey;       // toSearchKey
    final looseKey  = _nameController.looseSearchKey;  // toLooseSearchKey
    final display   = _nameController.displayKey;      // toDisplayKey
    final slug      = _nameController.slug;            // toSlug

    print('الاسم الأصلي:  $original');
    print('مفتاح البحث:   $searchKey');
    print('مفتاح متساهل:  $looseKey');
    print('للعرض:         $display');
    print('المعرّف:         $slug');

    // حفظ في قاعدة البيانات:
    saveRecord(name: original, searchKey: searchKey);
  }

  void _normalizeManually() {
    // الطريقة الوحيدة لتغيير النص — يجب استدعاؤها صراحةً
    _nameController.normalizeInPlace(
      const ArabicNormalizeOptions(
        removeTashkeel: true,
        normalizeAlef: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ArabicTextField(controller: _nameController),
        ElevatedButton(onPressed: _onSave, child: const Text('حفظ')),
        TextButton(onPressed: _normalizeManually, child: const Text('تعيير')),
      ],
    );
  }
}
```

#### `ArabicSearchController`

مخصص لحقول البحث. يُوفّر `searchKey` و `looseSearchKey` فقط.

```dart
final _searchController = ArabicSearchController();

// في كل تغيير:
_searchController.addListener(() {
  final query = _searchController.looseSearchKey;
  // استخدم query للاستعلام
});
```

> **تحذير:** لا تُطبّق هذه الـ controllers تعييراً تلقائياً على النص المرئي. الـ getters تحسب قيمتها عند كل استدعاء من `text` الحالي. إذا أردت تغيير النص المرئي استخدم `ArabicInputFormatter` كـ formatter في الـ widget.

---

### الـ Validators

جميع الـ validators متوافقة مع `TextFormField.validator`. تُعيد `null` عند النجاح، وتُعيد رسالة خطأ عربية عند الفشل. **لا تُغيّر قيمة الحقل أبداً.**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_arabic_ui/flutter_arabic_ui.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});
  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // 1. حقل مطلوب بالعربية
          TextFormField(
            controller: _nameController,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(labelText: 'الاسم الكامل'),
            validator: ArabicValidators.requiredArabic,
            // يرفض: فارغ أو مسافات فقط
            // رسالة الخطأ: 'هذا الحقل مطلوب'
          ),
          const SizedBox(height: 12),

          // 2. حروف عربية فقط
          TextFormField(
            controller: _cityController,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(labelText: 'المدينة'),
            validator: ArabicValidators.arabicOnly,
            // يرفض: أي نص يحتوي على غير عربية (حتى رقم واحد)
            // رسالة الخطأ: 'يجب إدخال نص عربي فقط'
          ),
          const SizedBox(height: 12),

          // 3. حد أدنى لعدد الأحرف العربية
          TextFormField(
            controller: _notesController,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'الملاحظات',
              helperText: 'ثلاثة أحرف عربية على الأقل',
            ),
            validator: ArabicValidators.minArabicLetters(3),
            // يرفض: نصوص بأقل من 3 أحرف عربية
            // رسالة الخطأ: 'عدد الأحرف العربية أقل من المطلوب'
          ),
          const SizedBox(height: 12),

          // 4. رقم فقط (يقبل الأرقام الغربية والعربية والفارسية)
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'العمر'),
            validator: ArabicValidators.numericArabic,
            // يقبل: 25 أو ٢٥ أو ۲۵
            // يرفض: 'أ' أو 'abc'
            // رسالة الخطأ: 'يجب إدخال رقم صحيح'
          ),
          const SizedBox(height: 24),

          // 5. نص مختلط — يشترط وجود عربية على الأقل
          // validator: ArabicValidators.mixedArabicText
          // رسالة الخطأ: 'يجب أن يحتوي النص على أحرف عربية'

          // 6. حد أقصى للأحرف العربية
          // validator: ArabicValidators.maxArabicLetters(100)
          // رسالة الخطأ: 'عدد الأحرف العربية أكبر من المسموح'

          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // جميع الحقول صحيحة
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }
}
```

**ملخص الـ validators:**

| الـ Validator | يقبل | يرفض | رسالة الخطأ |
|---|---|---|---|
| `requiredArabic` | أي نص غير فارغ | فارغ أو مسافات | هذا الحقل مطلوب |
| `arabicOnly` | نص عربي بحت | أي حرف غير عربي | يجب إدخال نص عربي فقط |
| `mixedArabicText` | أي نص يحوي عربية | بلا عربية أو فارغ | يجب أن يحتوي النص على أحرف عربية |
| `minArabicLetters(n)` | ≥ n حرفاً عربياً | أقل من n | عدد الأحرف العربية أقل من المطلوب |
| `maxArabicLetters(n)` | ≤ n حرفاً عربياً | أكثر من n | عدد الأحرف العربية أكبر من المسموح |
| `numericArabic` | 0-9 أو ٠-٩ أو ۰-۹ | حروف أو رموز | يجب إدخال رقم صحيح |

---

## 5. أسئلة شائعة

### لماذا لا تُحوَّل ة إلى ه في البحث الافتراضي؟

**لأن التاء المربوطة (ة) ذات معنى لغوي.** «فاطمة» اسم مختلف عن «فاطمه» من الناحية الإملائية، وقد تريد قواعد البيانات الحفاظ على هذا التمييز.

`toSearchKey` يحافظ على ة عمداً — وهو السلوك الصحيح **لتخزين** مفاتيح البحث.

`toLooseSearchKey` يُحوّل ة→ه — وهو مناسب للمطابقة المرنة عندما تقبل الشكلين. طبّقه على **المفتاح المخزن المتساهل والاستعلام معاً**؛ لا تقارنه بعمود `toSearchKey` الصارم.

---

### ما الفرق بين `arabic_text` و `arabic_bidi`؟

| | `arabic_text` | `arabic_bidi` |
|---|---|---|
| **الهدف** | توحيد النص وفهرسته | عرض النص صحيحاً في الطرفية |
| **المدخل** | أي نص عربي | نص عربي للعرض في CLI |
| **المخرج** | مفاتيح بحث وفرز وتسوية | نص جاهز للطباعة في الطرفية |
| **البيئة** | Dart + Flutter + CLI | CLI فقط |
| **هل تُغيّر المعنى** | لا — تُغيّر الشكل فقط | نعم — تُعيد ترتيب الأحرف بصرياً |

---

### هل أحتاج `arabic_bidi` في تطبيق Flutter؟

**لا.** Flutter يرسم النص العربي بشكل صحيح تلقائياً باستخدام محرك الرسم الخاص به. `arabic_bidi` مُصمَّمة حصراً للطرفية والـ CLI.

إذا أضفت `arabic_bidi` في تطبيق Flutter وطبّقت `prepareForTerminal` على نص ستعرضه في `Text` widget، ستحصل على نص مشوه لأن Flutter سيُطبّق خوارزمية BiDi الخاصة به **فوق** التحويل الذي أجرته المكتبة.

---

### كيف أستخدم المكتبات مع Supabase؟

**نمط الحفظ:** احفظ النص الأصلي ومفتاح البحث الصارم في عمودين منفصلين. أضف مفتاحاً متساهلاً **اختيارياً** إن أردت مطابقة ة/ه. لا تغيّر المفاتيح الصارمة القائمة.

```dart
import 'package:arabic_text/arabic_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// حفظ طالب جديد: النص الأصلي + المفتاحان (المتساهل اختياري)
Future<void> insertStudent({
  required String fullName,
  required String city,
}) async {
  await supabase.from('students').insert({
    'full_name': fullName,                                      // للعرض
    'name_search_key': ArabicText.toSearchKey(fullName),        // صارم
    'name_search_key_loose': ArabicText.toLooseSearchKey(fullName),
    'city': city,
    'city_search_key': ArabicText.toSearchKey(city),
    'city_search_key_loose': ArabicText.toLooseSearchKey(city),
  });
}

String escapeLike(String value) => value
    .replaceAll(r'\', r'\\')
    .replaceAll('%', r'\%')
    .replaceAll('_', r'\_');

// بحث متساهل حرفي: متساهل/متساهل — لا تستخدم name_search_key هنا
Future<List<Map<String, dynamic>>> searchStudents(String query) async {
  final key = ArabicText.toLooseSearchKey(query.trim());
  if (key.isEmpty) return const [];
  final pattern = '%${escapeLike(key)}%';
  return await supabase
      .from('students')
      .select('full_name, city')
      .like('name_search_key_loose', pattern);
}

// ترتيب النتائج بالمفتاح الصارم:
Future<List<String>> getSortedNames() async {
  final rows = await supabase
      .from('students')
      .select('full_name')
      .order('name_search_key', ascending: true);
  return rows.map<String>((r) => r['full_name'] as String).toList();
}
```

**إضافة الأعمدة في Supabase (اختيارية وغير هدّامة):**

```sql
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS name_search_key_loose text,
  ADD COLUMN IF NOT EXISTS city_search_key_loose text;

UPDATE students
SET name_search_key_loose = replace(name_search_key, 'ة', 'ه'),
    city_search_key_loose = replace(city_search_key, 'ة', 'ه')
WHERE name_search_key IS NOT NULL;

-- بادئة فقط:
CREATE INDEX IF NOT EXISTS idx_students_name_loose_prefix
  ON students (name_search_key_loose text_pattern_ops);
-- للاحتواء %query% استخدم pg_trgm، وليس text_pattern_ops.
```

`escapeLike` أعلاه يفرّ `\` ثم `%` ثم `_`، ويُمرَّر الناتج كقيمة نمط إلى `.like()`؛ لا تدمج نص المستخدم في SQL. استعلام فارغ يُعاد قبل الإرسال (`key.isEmpty`). تحققنا من **HTTP مباشر** إلى PostgREST 14.10 + PostgreSQL 16 محلياً؛ لم تُختبر استدعاءات SDK أو الخدمة المستضافة، فأعد الاختبار إذا كان إصدارك مختلفاً.

---

## 6. خارطة الطريق

هذه الميزات مقررة في الإصدارات المستقبلية:

| الميزة | الوصف |
|---|---|
| **TypeScript port** | نفس العقد السلوكي (SPEC.md) مُطبَّقاً في TypeScript للاستخدام في تطبيقات الويب و Node.js |
| **Python port** | منفذ Python للاستخدام في سكريبتات معالجة البيانات وتطبيقات AI |
| **HijriDatePicker** | منتقي تاريخ هجري لـ Flutter مع تحويل كامل بين التقويمين |
| **ArabicCollator** | ترتيب أبجدي عربي كامل يأخذ في الاعتبار حذف ال التعريف وترتيب ة/ه |

للمتابعة وتقديم الاقتراحات: [github.com/devsamhan/devsamhan-arabic](https://github.com/devsamhan/devsamhan-arabic)
