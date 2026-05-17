# devsamhan-arabic-text-pipeline

طبقة معالجة النصوص العربية بعد الاستخراج — إصلاح، جودة، تقسيم.

---

## ⚠️ إصدار Alpha (v0.1.0)

هذا إصدار تجريبي. السلوك قد يتغير في الإصدارات القادمة.

---

## ما هي هذه المكتبة؟

تعمل هذه المكتبة **بعد** استخراج النص من PDF أو OCR أو HTML.
تنظّف النص العربي وتحسّن جودته وتهيّئه للبحث أو النماذج اللغوية (LLM).

```
PDF / OCR / HTML
      ↓
النص الخام المستخرج
      ↓
arabic_text_pipeline  ←  أنت هنا
      ↓
نص نظيف + تقرير جودة + تقسيم دلالي (chunks)
```

---

## ما لا تفعله المكتبة

- ❌ لا تستخرج نصاً من PDF — استخدم [PyMuPDF](https://pymupdf.readthedocs.io/) أو [pdfplumber](https://github.com/jsvine/pdfplumber)
- ❌ لا تقوم بـ OCR — استخدم [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR) أو [Tesseract](https://github.com/tesseract-ocr/tesseract)
- ❌ لا تُطبّع النص الصحيح — استخدم [arabic_text](https://pypi.org/project/devsamhan-arabic-text/) لذلك
- ❌ لا تعدّل المعنى أو تضيف كلمات — معالجة حتمية فقط

---

## التثبيت

```bash
pip install devsamhan-arabic-text-pipeline
```

للتطوير:

```bash
pip install "devsamhan-arabic-text-pipeline[dev]"
```

---

## الدوال الأساسية

### analyze_quality — تقييم جودة النص

يفحص النص ويُعيد تقرير جودة مع رموز مشاكل مسمّاة.

```python
from devsamhan_arabic_text_pipeline import analyze_quality

result = analyze_quality("مـحـمـد يذهب إلى المدرسة رقم ١٢3")

print(result["quality"])       # "warning"
print(result["arabic_ratio"])  # 0.7059
print(result["issues"])
# [
#   {"code": "AQ001_EXCESSIVE_TATWEEL", "severity": "low",
#    "message": "Tatweel (kashida) found inside 3 Arabic word position(s)...", ...},
#   {"code": "AQ005_MIXED_DIGITS", "severity": "low",
#    "message": "Text contains both Western and Arabic-Indic/Persian digit forms.", ...}
# ]
```

مستويات الجودة: `"good"` / `"warning"` / `"poor"`

| الرمز | الوصف | الخطورة |
|-------|-------|---------|
| `AQ001_EXCESSIVE_TATWEEL` | تطويل (كشيدة) داخل كلمات عربية | low / medium |
| `AQ002_TASHKEEL_DENSE` | تشكيل كثيف | low |
| `AQ003_POSSIBLY_REVERSED` | نص مقلوب بصرياً | medium |
| `AQ004_SEPARATED_LETTERS` | حروف عربية مفصولة | medium |
| `AQ005_MIXED_DIGITS` | خلط أرقام غربية وعربية-هندية | low |
| `AQ006_OCR_NOISE` | أحرف ضجيج من OCR | medium / high |
| `AQ007_LOW_ARABIC_RATIO` | نسبة عربية منخفضة | medium / high |

---

### repair_text — إصلاح النص بأمان

يُصلح المشاكل الآمنة تلقائياً. المشاكل الخطرة تُعاد كاقتراحات فقط — **لا تُطبَّق أبداً**.

```python
from devsamhan_arabic_text_pipeline import repair_text

result = repair_text("مـحـمـد   بـن   عـبـد   الله")

print(result["repaired_text"])  # "محمد بن عبد الله"
print(result["changed"])        # True
print(result["issues_fixed"])   # ["AQ001_EXCESSIVE_TATWEEL"]
print(result["suggestions"])    # []
print(result["original_text"])  # "مـحـمـد   بـن   عـبـد   الله"  ← محفوظ دائماً
```

**الإصلاحات الآمنة (تُطبَّق تلقائياً):**
- حذف التطويل (كشيدة) من داخل الكلمات
- حذف أحرف اللاعرض (ZWSP، ZWNJ، ZWJ، BOM)
- حذف علامات BiDi الموجهة
- تطبيع المسافات والأسطر (CRLF → LF، مسافات متعددة → واحدة)

**الإصلاحات الخطرة (اقتراحات فقط، لا تُطبَّق):**
- `reverse_text` — إذا بدا النص مقلوباً بصرياً
- `merge_separated_letters` — إذا بدت الحروف مفصولة

---

### chunk_semantic — التقسيم الدلالي

يقسّم النص إلى أجزاء بناءً على العناوين العربية الهيكلية.

```python
from devsamhan_arabic_text_pipeline import chunk_semantic

text = """الفصل الأول: في أركان العقد
أركان العقد ثلاثة: الصيغة والعاقدان والمعقود عليه.

الفصل الثاني: في شروط الصحة
يشترط لصحة العقد أن يكون المحل موجوداً ومعلوماً."""

chunks = chunk_semantic(text)
# [
#   {"title": "الفصل الأول: في أركان العقد", "type": "section",
#    "text": "...", "start_index": 0, "end_index": 73},
#   {"title": "الفصل الثاني: في شروط الصحة", "type": "section",
#    "text": "...", "start_index": 75, "end_index": 152},
# ]
```

الكلمات المفتاحية المكتشفة وأنواع الأجزاء:

| الكلمة | النوع |
|--------|-------|
| الكتاب / كتاب | `book` |
| الباب / باب | `chapter` |
| الفصل / فصل | `section` |
| المبحث / مبحث | `topic` |
| المطلب / مطلب | `subtopic` |
| أولاً / ثانياً / … | `section` |
| *(بدون عناوين)* | `paragraph` |

`start_index` و `end_index` يشيران إلى مواضع في النص الأصلي: `text[start_index:end_index] == chunk["text"]`

---

### prepare_for_llm — إعداد شامل للنماذج اللغوية

يُشغّل خط المعالجة الكامل بنداء واحد.

```python
from devsamhan_arabic_text_pipeline import prepare_for_llm

result = prepare_for_llm(
    text,
    include_search_key=True,       # مفتاح بحث بدون تشكيل
    include_loose_search_key=True, # مفتاح بحث متساهل (توحيد الألفات والتاء)
    apply_repair=True,             # افتراضي
)

print(result["clean_text"])       # النص بعد الإصلاح والتطبيع
print(result["quality_report"])   # من analyze_quality()
print(result["repair_report"])    # من repair_text()، أو None
print(result["chunks"])           # من chunk_semantic()
print(result["search_key"])       # النص بدون تشكيل
print(result["loose_search_key"]) # النص موحَّد الألفات والتاء
print(result["warnings"])         # تحذيرات عملية
print(result["metadata"])         # إحصاءات ومعلومات الخط
```

التحذيرات الممكنة في `warnings`:

| التحذير | المعنى |
|---------|--------|
| `"empty_text"` | النص فارغ أو مسافات فقط |
| `"poor_quality"` | جودة النص `"poor"` |
| `"unsafe_repair_skipped"` | وُجدت مشاكل خطرة لم تُصلَح |
| `"tashkeel_preserved"` | تشكيل كثيف محفوظ (AQ002) |

---

## أمثلة عملية

### مثال 1: تنظيف نص مستخرج من PDF

```python
import pdfplumber
from devsamhan_arabic_text_pipeline import prepare_for_llm

with pdfplumber.open("contract.pdf") as pdf:
    raw_text = "\n".join(
        page.extract_text() or "" for page in pdf.pages
    )

result = prepare_for_llm(raw_text, include_search_key=True)

if result["warnings"]:
    print("تحذيرات:", result["warnings"])

print("الجودة:", result["metadata"]["quality"])
print("عدد الأجزاء:", result["metadata"]["chunk_count"])
print(result["clean_text"])
```

### مثال 2: فحص جودة مخرجات OCR

```python
from devsamhan_arabic_text_pipeline import analyze_quality

ocr_output = "الع|قد شريع€ة المتعاقدين"  # نص تالف من OCR

report = analyze_quality(ocr_output)

if report["quality"] == "poor":
    print("النص تالف — يُنصح بإعادة OCR")
elif report["quality"] == "warning":
    print("النص يحتاج مراجعة:")
    for issue in report["issues"]:
        print(f"  [{issue['severity'].upper()}] {issue['code']}: {issue['message']}")
else:
    print("النص سليم")
```

### مثال 3: إعداد نص فقهي لـ LLM مع تقسيم دلالي

```python
from devsamhan_arabic_text_pipeline import prepare_for_llm

with open("fiqh_text.txt", encoding="utf-8") as f:
    text = f.read()

result = prepare_for_llm(text, include_search_key=True)

# إرسال كل جزء بشكل منفصل للنموذج اللغوي
for chunk in result["chunks"]:
    payload = {
        "title": chunk["title"],
        "type": chunk["type"],
        "content": chunk["text"],
        "search_key": result["search_key"][
            chunk["start_index"]:chunk["end_index"]
        ] if result["search_key"] else None,
    }
    # send_to_llm(payload)
    print(f"[{chunk['type']}] {chunk['title']}: {len(chunk['text'])} حرف")
```

---

## العلاقة مع المكتبات الأخرى

| المكتبة | الدور | متى تستخدمها |
|---------|-------|--------------|
| [`arabic_text`](https://pypi.org/project/devsamhan-arabic-text/) | تطبيع النص الصحيح (بحث، ترتيب، slug) | النص سليم وتحتاج تطبيعاً |
| `arabic_text_pipeline` | إصلاح وتقييم النص المكسور أو المستخرج | النص جاء من OCR أو PDF أو مصدر غير موثوق |

---

## التطوير

```bash
python -m venv .venv
source .venv/bin/activate        # Linux/macOS
.venv\Scripts\activate           # Windows

pip install -e ".[dev]"
python -m pytest tests/ -v
```

المواصفات والحالات الاختبارية في [`../test_fixtures/`](../test_fixtures/).

---

## الترخيص

MIT — [Devsamhan](https://github.com/devsamhan)
