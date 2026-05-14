# @devsamhan/arabic-devtools

أدوات سطر الأوامر للمطور العربي — اكتشاف مشاكل النصوص العربية في المشاريع.

> **ملاحظة مهمة**: النسخة 0.1.0 للتشخيص فقط — لا تعديل تلقائي للملفات.
> لا يوجد خيار `--fix` في هذه النسخة. راجع النتائج يدوياً قبل إجراء أي تغيير.

## التثبيت

```bash
npm install -g @devsamhan/arabic-devtools
```

---

## الأوامر

### check-rtl \<المسار\>

يكتشف النصوص العربية المكتوبة بالعكس داخل الملفات.

**أمثلة على الأخطاء المكتشفة:**
- `ثحب` بدلاً من `بحث`
- `دمحم` بدلاً من `محمد`
- `فلم` بدلاً من `ملف`

```bash
arabic-devtools check-rtl ./lib
arabic-devtools check-rtl ./src --format json
arabic-devtools check-rtl ./src --severity-threshold high
```

الكود: **AR001** — مستويات الثقة: عالٍ (قاموس) / متوسط / منخفض

يخرج بكود 1 عند وجود نتائج، 0 عند النظافة.

---

### scan \<المسار\>

يفحص الملفات أو المجلدات عن مشاكل عربية شائعة:

- **AR002** — تطويل زائد: `مـحـمـد`
- **AR003** — تشكيل داخل مفاتيح البحث: `مُحَمَّد`
- **AR004** — خلط أرقام شرقية وغربية: `رقم ١٢3`
- **AR001** — نصوص عربية مقلوبة (كما في check-rtl)

```bash
arabic-devtools scan ./lib
arabic-devtools scan ./src --format json
arabic-devtools scan ./src --severity-threshold medium
```

في بيئة CI:
```bash
arabic-devtools scan . --format json
```

يخرج بكود 1 عند وجود نتائج، 0 عند النظافة.

---

### bidi "\<النص\>"

يحوّل النص العربي ليظهر بشكل صحيح في الطرفية (BiDi + تشكيل الحروف).

```bash
arabic-devtools bidi "مرحبا بالعالم"
```

يخرج دائماً بكود 0 (ما لم يغب المعامل).

---

## رموز القواعد

| الكود | الاسم | الخطورة |
|-------|-------|---------|
| AR001 | potentially-reversed-arabic-literal | عالية / متوسطة / منخفضة |
| AR002 | excessive-tatweel | متوسطة |
| AR003 | tashkeel-in-search-key | متوسطة |
| AR004 | mixed-digit-scripts | منخفضة |

جميع النتائج تشخيصية — لا إصلاح تلقائي.

التفاصيل الكاملة في [docs/rules.md](docs/rules.md).

---

## مثال على مخرجات JSON

```bash
arabic-devtools check-rtl ./src --format json
```

```json
{
  "tool": "arabic-devtools",
  "command": "check-rtl",
  "findings": [
    {
      "code": "AR001",
      "type": "potentially-reversed-arabic-literal",
      "severity": "high",
      "file": "src/strings.txt",
      "line": 12,
      "column": 18,
      "found": "ثحب",
      "suggestion": "بحث",
      "message": "Potentially reversed Arabic literal"
    }
  ]
}
```

---

## فلترة حسب الخطورة

```bash
arabic-devtools scan ./src --severity-threshold high
```

- `low` (الافتراضي) — كل النتائج
- `medium` — متوسط وعالٍ فقط
- `high` — عالٍ فقط

---

## المكتبات المستخدمة

- [@devsamhan/arabic-text](https://www.npmjs.com/package/@devsamhan/arabic-text) — تطبيع النص العربي
- [@devsamhan/arabic-bidi](https://www.npmjs.com/package/@devsamhan/arabic-bidi) — عرض العربية في الطرفية

## الترخيص

MIT — [Devsamhan](https://github.com/devsamhan)
