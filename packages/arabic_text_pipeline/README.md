# arabic_text_pipeline

طبقة معالجة النصوص العربية بعد الاستخراج — Python أولاً.
الإصدار: v0.1.0 (Alpha)

---

## ما تفعله هذه الحزمة

تأتي بعد استخراج النص من PDF أو OCR. تستقبل نصاً مستخرجاً بالفعل وتحسّنه وتحلله وتجهّزه للاستخدام.

---

## أين تقع في سلسلة المعالجة

```
[Image / PDF file]
       ↓
[OCR engine / PDF extractor]   ← ليست هذه الحزمة
       ↓
[Raw extracted Arabic text]
       ↓
arabic_text_pipeline           ← أنت هنا
       ↓
[نص نظيف + تقرير جودة + chunks]
```

---

## ما لا تفعله

- ❌ لا تستخرج نصاً من PDF
- ❌ لا تقوم بـ OCR
- ❌ ليست بديلاً عن arabic_text للتطبيع

---

## التثبيت

```bash
pip install devsamhan-arabic-text-pipeline
```

---

## الدوال

- `analyze_quality(text)` — تقرير جودة شامل
- `repair_text(text)` — إصلاح آمن للنص المكسور
- `chunk_semantic(text)` — تقسيم دلالي للنص
- `prepare_for_llm(text)` — تجهيز النص للنماذج اللغوية

---

## المنصات

| اللغة | الحالة |
|-------|--------|
| Python | PyPI ✅ |
| TypeScript | قادماً |
| Dart | قادماً |

---

## التوثيق

- [`python/README.md`](python/README.md) — توثيق الدوال بالتفصيل
- [`test_fixtures/SPEC.md`](test_fixtures/SPEC.md) — العقد السلوكي

---

## الترخيص

MIT — [Devsamhan](https://github.com/devsamhan)
