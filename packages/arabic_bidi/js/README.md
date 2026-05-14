# @devsamhan/arabic-bidi

مكتبة JavaScript/TypeScript لعرض النص العربي صحيحاً في الطرفية — إعادة تشكيل الحروف، كشف الاتجاه، سجل عربي.

بدون تبعيات خارجية عدا `@devsamhan/arabic-text`. متوافقة مع [مواصفات devsamhan-arabic v1.0.0](https://github.com/devsamhan/devsamhan-arabic).

## التثبيت

```bash
npm install @devsamhan/arabic-bidi
```

```typescript
import {
  reshape, prepareForTerminal, printArabic,
  detectDirection, Direction,
  ArabicLogger, arabicLogger,
} from '@devsamhan/arabic-bidi';
```

---

## الاستخدام السريع

```typescript
// إعادة تشكيل الحروف (الحروف المعزولة → أشكال السياق)
reshape('بيت');                     // → 'ﺑﻴﺖ'

// تجهيز النص للطرفية (تشكيل + إعادة ترتيب المقاطع)
prepareForTerminal('مرحبا Hello');  // → 'Hello ﻣﺮﺣﺒﺎ'

// طباعة مباشرة
printArabic('مرحبا بالعالم');

// كشف الاتجاه
detectDirection('مرحبا');   // → Direction.RTL
detectDirection('Hello');   // → Direction.LTR
detectDirection('Hi مرحبا');// → Direction.MIXED

// سجل عربي
arabicLogger.info('تم التشغيل');
new ArabicLogger({ prefix: 'خادم', useTimestamp: true }).error('فشل الاتصال');
```

---

## الـ API

| الدالة | الوصف |
|---|---|
| `reshape(text, options?)` | تحويل الحروف إلى أشكال السياق (معزول/أول/وسط/أخير). |
| `prepareForTerminal(text, options?)` | تشكيل + إعادة ترتيب مقاطع النص لعرض صحيح في الطرفية. |
| `printArabic(text, options?)` | طباعة النص بعد التجهيز. |
| `detectDirection(text)` | يُعيد `Direction.RTL` أو `LTR` أو `MIXED`. |
| `arabicLogger` | نسخة جاهزة من `ArabicLogger`. |

### ReshapeOptions

| خيار | النوع | الافتراضي | الوصف |
|---|---|---|---|
| `useLamAlefLigatures` | `boolean` | `false` | دمج لام+ألف في حرف واحد (U+FEF5–U+FEFC). |

### TerminalOptions

| خيار | النوع | الافتراضي | الوصف |
|---|---|---|---|
| `reshape` | `boolean` | `true` | تفعيل إعادة التشكيل. |
| `reorder` | `boolean` | `true` | إعادة ترتيب المقاطع لعرض RTL في الطرفية. |
| `useLamAlefLigatures` | `boolean` | `false` | تمرير إلى reshape. |

### ArabicLogger

```typescript
new ArabicLogger({
  prefix?: string,          // يُضاف بين قوسين قبل المستوى
  useTimestamp?: boolean,   // افتراضي: false
  terminalOptions?: TerminalOptions,
})
```

تنسيق المخرجات: `[yyyy-MM-dd HH:mm:ss][prefix][LEVEL] message`

---

## الترخيص

MIT — [Devsamhan](https://github.com/devsamhan)
