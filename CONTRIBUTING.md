# المساهمة في مكتبات devsamhan-arabic

## قبل كل شيء: اقرأ المواصفات

اقرأ [`test_fixtures/SPEC.md`](test_fixtures/SPEC.md) أولاً.

`test_fixtures/` هي **العقد السلوكي** للمكتبات — لا يُعتمد على الكود الداخلي، بل على ما تقوله الـ fixtures. أي منفذ (Dart أو TypeScript أو Python) يجب أن يجتاز 100% من الـ fixtures قبل الدمج.

---

## قواعد التعديل

### الـ fixtures أولاً

- لا تعدّل كوداً قبل أن تفهم الـ fixture المقابلة له.
- لا تعدّل الـ fixtures إلا لسبب موثّق وبإجماع واضح.
- أي تغيير في سلوك دالة يستلزم تحديث `test_fixtures/` **أولاً**، ثم رفع `SPEC_VERSION` إذا تغيّر العقد السلوكي.

### الـ API

| المنصة | اصطلاح التسمية |
|---|---|
| Dart | camelCase |
| TypeScript | camelCase |
| Python | snake_case |

الأسماء المقابلة بين المنصات يجب أن تكون واضحة بالترجمة الطبيعية (مثال: `toSearchKey` ↔ `to_search_key`).

### التبعيات

- لا تضف تبعية خارجية إلا لسبب قوي وموثّق.
- `arabic_bidi` لا يعتمد على `arabic_text` في وقت التشغيل — أي دالة مشتركة تُنسخ محلياً للحفاظ على الاستقلالية.

---

## تحذيرات تقنية

- **لا تدّعِ أن `arabic_bidi` يطبق UAX #9 كاملاً** — المكتبة تطبق خوارزمية مبسّطة كافية للـ CLI والـ logs؛ ليست بديلاً لـ ICU أو مكتبات BiDi الكاملة.
- **النص الأصلي محفوظ دائماً** — `toSearchKey` / `to_search_key` وما يماثلها تنتج قيماً مشتقة للبحث والعرض فقط، لا تُخزَّن بديلاً عن الأصل.
- **الفرز بسيط** — `sort` / `sort_arabic` يعتمد على مفاتيح بحث مُطبَّعة، ليس على خوارزميات Unicode Collation كاملة.

---

## تشغيل الاختبارات

### Dart
```bash
cd packages/arabic_text/dart
dart test

cd packages/arabic_bidi/dart
dart test
```

### TypeScript
```bash
cd packages/arabic_text/js
npm test

cd packages/arabic_bidi/js
npm test
```

### Python
```bash
cd packages/arabic_text/python
python -m pytest tests/ -v

cd packages/arabic_bidi/python
python -m pytest tests/ -v
```

---

## إضافة منفذ جديد

1. اقرأ `test_fixtures/SPEC.md` واستوعب جميع حالات الـ fixtures.
2. أنشئ المجلد تحت `packages/<package>/<language>/`.
3. طبّق الـ API بالاصطلاح الصحيح للغة.
4. اكتب اختبارات تمر بجميع الـ fixtures — الاجتياز الكامل شرط للدمج.
5. لا تضف features غير موجودة في SPEC — الهدف توافق السلوك لا إثراؤه.

---

## الالتزام بالمواصفة

أي سلوك غير مغطى بـ `test_fixtures/` يُعدّ **غير معرَّف** — لا تعتمد عليه ولا تُرسّخه في الكود.
