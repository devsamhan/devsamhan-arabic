# flutter_arabic_ui

مكوّنات Flutter مبنية للعربية — حقول نص، بحث، أرقام، تحقق، controllers.

بدون آراء تصميمية. كل شيء يمر إلى `TextField` الأصلي كما هو.

جزء من مجموعة [devsamhan-arabic](https://github.com/devsamhan/devsamhan-arabic).

---

## التثبيت

```yaml
dependencies:
  flutter_arabic_ui: ^1.0.0
```

```dart
import 'package:flutter_arabic_ui/flutter_arabic_ui.dart';
```

---

## المكوّنات

### `ArabicTextField`

حقل إدخال عربي مع RTL تلقائي وخيار التطبيع الحي.

```dart
// بدون تطبيع — النص يبقى كما يكتبه المستخدم
ArabicTextField(
  controller: _controller,
  decoration: const InputDecoration(
    labelText: 'اسم الطالب',
    border: OutlineInputBorder(),
  ),
  onChanged: (text) => print(text),
)

// مع تطبيع تلقائي — يُزيل التشكيل والتطويل عند كل ضغطة
ArabicTextField(
  controller: _controller,
  autoNormalize: true,
  normalizeOptions: const ArabicNormalizeOptions(
    removeTashkeel: true,
    removeTatweel: true,
    normalizeAlef: true,
  ),
  decoration: const InputDecoration(
    labelText: 'بحث',
    border: OutlineInputBorder(),
  ),
)
```

> **تحذير:** لا تُفعّل `autoNormalize: true` في حقول الأسماء إذا كنت تريد حفظ الاسم بشكله الأصلي. التطبيع التلقائي يُغيّر النص المرئي للمستخدم مباشرةً.

---

### `ArabicSearchField`

حقل بحث يُولّد مفتاح بحث معياراً في كل تغيير.

- `onChanged` — يُعطيك النص الخام كما كتبه المستخدم
- `onSearchKeyChanged` — يُعطيك `toSearchKey(raw)` جاهزاً للاستعلام

```dart
ArabicSearchField(
  onChanged: (rawText) {
    // النص كما كتبه المستخدم
  },
  onSearchKeyChanged: (searchKey) {
    // مفتاح البحث المُعيَّر — استخدمه للاستعلام
    _filterList(searchKey);
  },
  decoration: const InputDecoration(
    hintText: 'ابحث عن اسم...',
    prefixIcon: Icon(Icons.search),
    border: OutlineInputBorder(),
  ),
)
```

**مثال بحث متساهل (يقبل فاطمة وفاطمه):**

```dart
import 'package:arabic_text/arabic_text.dart';

void _onSearchChanged(String raw) {
  final queryKey = ArabicText.toLooseSearchKey(raw);
  setState(() {
    _results = raw.isEmpty
        ? _allItems
        : _allItems.where((item) =>
            ArabicText.toLooseSearchKey(item).contains(queryKey)).toList();
  });
}
```

---

### `ArabicNumberField`

حقل أرقام يُحوّل أشكال الأرقام تلقائياً عند كل ضغطة.

```dart
// يُحوّل الأرقام العربية/الفارسية إلى غربية (0-9)
ArabicNumberField(
  controller: _phoneController,
  digitDirection: ArabicDigitDirection.western,
  decoration: const InputDecoration(
    labelText: 'رقم الهاتف',
    border: OutlineInputBorder(),
  ),
  onNormalizedChanged: (westernDigits) {
    // westernDigits دائماً بالأرقام الغربية 0-9
    // آمن للتحويل إلى int/double مباشرة
    final number = int.tryParse(westernDigits);
  },
)

// يُحوّل الأرقام الغربية إلى عربية شرقية (٠-٩)
ArabicNumberField(
  digitDirection: ArabicDigitDirection.eastern,
  decoration: const InputDecoration(
    labelText: 'المبلغ',
    hintText: '١٢٣٤٥',
  ),
  onChanged: (displayValue) => print('المعروض: $displayValue'),       // ٠-٩
  onNormalizedChanged: (western) => print('للحساب: $western'),         // 0-9
)
```

---

## الـ Formatters مباشرةً

يمكن تركيبها على أي `TextFormField` أو `TextField` عادي.

```dart
// يُزيل التشكيل والتطويل عند كل ضغطة
TextField(
  inputFormatters: const [ArabicInputFormatter()],
)

// مع خيارات مخصصة
TextField(
  inputFormatters: [
    ArabicInputFormatter(
      options: const ArabicNormalizeOptions(
        removeTashkeel: true,
        normalizeAlef: true,
        normalizeHamza: true,
      ),
    ),
  ],
)

// تحويل الأرقام فقط
TextField(
  inputFormatters: [
    const ArabicNumberFormatter(direction: ArabicDigitDirection.eastern),
  ],
)
```

---

## الـ Controllers

### `ArabicTextEditingController`

يمتد `TextEditingController` بـ getters للقراءة فقط. **النص لا يتغير تلقائياً أبداً.**

```dart
final _controller = ArabicTextEditingController();

// في أي وقت:
print(_controller.text);          // النص الأصلي
print(_controller.searchKey);     // ArabicText.toSearchKey(text)
print(_controller.looseSearchKey); // ArabicText.toLooseSearchKey(text)
print(_controller.displayKey);    // ArabicText.toDisplayKey(text)
print(_controller.slug);          // ArabicText.toSlug(text)

// عند الحفظ:
void onSave() {
  saveRecord(
    name: _controller.text,
    searchKey: _controller.searchKey,
  );
}

// التطبيع اليدوي الصريح — الطريقة الوحيدة لتغيير النص:
void onNormalize() {
  _controller.normalizeInPlace(
    const ArabicNormalizeOptions(removeTashkeel: true, normalizeAlef: true),
  );
}
```

### `ArabicSearchController`

للبحث فقط. يُوفّر `searchKey` و `looseSearchKey`.

```dart
final _searchController = ArabicSearchController();

_searchController.addListener(() {
  final query = _searchController.looseSearchKey;
  _filterResults(query);
});
```

---

## الـ Validators

متوافقة مع `TextFormField.validator`. تُعيد `null` عند النجاح، وتُعيد رسالة خطأ عربية عند الفشل. **لا تُغيّر قيمة الحقل أبداً.**

```dart
Form(
  key: _formKey,
  child: Column(
    children: [
      // حقل مطلوب بالعربية
      TextFormField(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        decoration: const InputDecoration(labelText: 'الاسم'),
        validator: ArabicValidators.requiredArabic,
        // رسالة الخطأ: 'هذا الحقل مطلوب'
      ),

      // حروف عربية فقط
      TextFormField(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        decoration: const InputDecoration(labelText: 'المدينة'),
        validator: ArabicValidators.arabicOnly,
        // رسالة الخطأ: 'يجب إدخال نص عربي فقط'
      ),

      // حد أدنى للأحرف العربية
      TextFormField(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        decoration: const InputDecoration(labelText: 'الملاحظات'),
        validator: ArabicValidators.minArabicLetters(3),
        // رسالة الخطأ: 'عدد الأحرف العربية أقل من المطلوب'
      ),

      // حد أقصى للأحرف العربية
      TextFormField(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        decoration: const InputDecoration(labelText: 'الوصف'),
        validator: ArabicValidators.maxArabicLetters(100),
        // رسالة الخطأ: 'عدد الأحرف العربية أكبر من المسموح'
      ),

      // رقم فقط — يقبل الغربية والعربية والفارسية
      TextFormField(
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'العمر'),
        validator: ArabicValidators.numericArabic,
        // يقبل: 25 أو ٢٥ أو ۲۵
        // رسالة الخطأ: 'يجب إدخال رقم صحيح'
      ),

      // نص مختلط — يشترط وجود عربية على الأقل
      TextFormField(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        decoration: const InputDecoration(labelText: 'ملاحظة'),
        validator: ArabicValidators.mixedArabicText,
        // رسالة الخطأ: 'يجب أن يحتوي النص على أحرف عربية'
      ),

      ElevatedButton(
        onPressed: () => _formKey.currentState!.validate(),
        child: const Text('تحقق'),
      ),
    ],
  ),
)
```

**ملخص الـ Validators:**

| الـ Validator | شرط القبول | رسالة الخطأ |
|---|---|---|
| `requiredArabic` | غير فارغ بعد الـ trim | هذا الحقل مطلوب |
| `arabicOnly` | جميع الأحرف عربية | يجب إدخال نص عربي فقط |
| `mixedArabicText` | يحتوي على عربية على الأقل | يجب أن يحتوي النص على أحرف عربية |
| `minArabicLetters(n)` | عدد الأحرف العربية ≥ n | عدد الأحرف العربية أقل من المطلوب |
| `maxArabicLetters(n)` | عدد الأحرف العربية ≤ n | عدد الأحرف العربية أكبر من المسموح |
| `numericArabic` | رقم صحيح (0-9 أو ٠-٩ أو ۰-۹) | يجب إدخال رقم صحيح |

---

## الترخيص

MIT — [Devsamhan](https://github.com/devsamhan)
