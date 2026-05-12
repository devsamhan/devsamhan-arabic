import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_text/arabic_text.dart';
import 'package:flutter_arabic_ui/flutter_arabic_ui.dart';

const _empty = TextEditingValue.empty;

TextEditingValue _val(String text) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

// ── Phase 1: formatter unit tests ────────────────────────────────────────────

void main() {
  group('ArabicInputFormatter', () {
    test('tashkeel removed on input', () {
      final fmt = ArabicInputFormatter();
      final result = fmt.formatEditUpdate(_empty, _val('مُحَمَّد'));
      expect(result.text, equals('محمد'));
    });

    test('tatweel removed on input', () {
      final fmt = ArabicInputFormatter();
      final result = fmt.formatEditUpdate(_empty, _val('مـحـمـد'));
      expect(result.text, equals('محمد'));
    });

    test('alef normalized', () {
      final fmt = ArabicInputFormatter(
        options: const ArabicNormalizeOptions(normalizeAlef: true),
      );
      final result = fmt.formatEditUpdate(_empty, _val('أحمد'));
      expect(result.text, equals('احمد'));
    });

    test('Latin text passes through unchanged', () {
      final fmt = ArabicInputFormatter();
      final result = fmt.formatEditUpdate(_empty, _val('hello'));
      expect(result.text, equals('hello'));
    });

    test('unchanged value returned as the same object', () {
      final fmt = ArabicInputFormatter();
      final value = _val('محمد');
      expect(fmt.formatEditUpdate(_empty, value), same(value));
    });

    test('cursor offset adjusted after tashkeel removal', () {
      final fmt = ArabicInputFormatter();
      // 'مُ' (mim + damma) → 'م'; cursor after 'مُ' (offset 2) → after 'م' (offset 1).
      final input = TextEditingValue(
        text: 'مُد',
        selection: TextSelection.collapsed(offset: 2),
      );
      final result = fmt.formatEditUpdate(_empty, input);
      expect(result.text, equals('مد'));
      expect(result.selection.extentOffset, equals(1));
    });
  });

  group('ArabicNumberFormatter', () {
    test('eastern digits → western', () {
      final fmt =
          ArabicNumberFormatter(direction: ArabicDigitDirection.western);
      final result = fmt.formatEditUpdate(_empty, _val('١٢٣'));
      expect(result.text, equals('123'));
    });

    test('western digits → eastern', () {
      final fmt =
          ArabicNumberFormatter(direction: ArabicDigitDirection.eastern);
      final result = fmt.formatEditUpdate(_empty, _val('123'));
      expect(result.text, equals('١٢٣'));
    });

    test('Persian digits → western', () {
      final fmt =
          ArabicNumberFormatter(direction: ArabicDigitDirection.western);
      final result = fmt.formatEditUpdate(_empty, _val('۱۲۳'));
      expect(result.text, equals('123'));
    });

    test('mixed eastern and western digits normalized', () {
      final fmt =
          ArabicNumberFormatter(direction: ArabicDigitDirection.western);
      final result = fmt.formatEditUpdate(_empty, _val('١23٣'));
      expect(result.text, equals('1233'));
    });

    test('unchanged value returned as the same object', () {
      final fmt =
          ArabicNumberFormatter(direction: ArabicDigitDirection.western);
      final value = _val('123');
      expect(fmt.formatEditUpdate(_empty, value), same(value));
    });
  });

  group('ArabicSearchKeyFormatter', () {
    test('toSearchKey applied — tashkeel and alef stripped', () {
      final fmt = ArabicSearchKeyFormatter();
      final result = fmt.formatEditUpdate(_empty, _val('مُحَمَّد'));
      expect(result.text, equals(ArabicText.toSearchKey('مُحَمَّد')));
    });

    test('alef normalization via search key', () {
      final fmt = ArabicSearchKeyFormatter();
      final result = fmt.formatEditUpdate(_empty, _val('أحمد'));
      expect(result.text, equals(ArabicText.toSearchKey('أحمد')));
    });

    test('Latin text preserved', () {
      final fmt = ArabicSearchKeyFormatter();
      final result = fmt.formatEditUpdate(_empty, _val('hello'));
      expect(result.text, equals('hello'));
    });

    test('unchanged value returned as the same object', () {
      final fmt = ArabicSearchKeyFormatter();
      final value = _val('محمد');
      expect(fmt.formatEditUpdate(_empty, value), same(value));
    });
  });

  // ── Phase 2: widget tests ───────────────────────────────────────────────────

  group('ArabicTextField', () {
    testWidgets('defaults: textDirection RTL, textAlign right', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ArabicTextField()),
      ));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.textDirection, equals(TextDirection.rtl));
      expect(tf.textAlign, equals(TextAlign.right));
    });

    testWidgets('autoNormalize false: raw text preserved', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ArabicTextField(controller: controller)),
      ));
      await tester.enterText(find.byType(TextField), 'مُحَمَّد');
      expect(controller.text, equals('مُحَمَّد'));
    });

    testWidgets('autoNormalize true: tashkeel removed on input',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ArabicTextField(
            controller: controller,
            autoNormalize: true,
          ),
        ),
      ));
      await tester.enterText(find.byType(TextField), 'مُحَمَّد');
      expect(controller.text, equals('محمد'));
    });

    testWidgets('onChanged fires with current text', (tester) async {
      String? captured;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ArabicTextField(onChanged: (v) => captured = v),
        ),
      ));
      await tester.enterText(find.byType(TextField), 'محمد');
      expect(captured, equals('محمد'));
    });
  });

  group('ArabicSearchField', () {
    testWidgets('visible text stays raw (normalizeVisibleText: false default)',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ArabicSearchField(controller: controller)),
      ));
      await tester.enterText(find.byType(TextField), 'مُحَمَّد');
      expect(controller.text, equals('مُحَمَّد'));
    });

    testWidgets('onSearchKeyChanged emits toSearchKey(raw)', (tester) async {
      String? captured;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ArabicSearchField(
            onSearchKeyChanged: (v) => captured = v,
          ),
        ),
      ));
      await tester.enterText(find.byType(TextField), 'مُحَمَّد');
      expect(captured, equals(ArabicText.toSearchKey('مُحَمَّد')));
    });

    testWidgets('default hintText equals exactly بحث', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ArabicSearchField()),
      ));
      final tf = tester.widget<TextField>(find.byType(TextField));
      final hint = tf.decoration?.hintText;
      expect(hint, equals('بحث'));
      expect(hint!.runes.toList(), equals([0x0628, 0x062D, 0x062B]));
    });

    testWidgets('normalizeVisibleText true: visible text normalized',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ArabicSearchField(
            controller: controller,
            normalizeVisibleText: true,
          ),
        ),
      ));
      await tester.enterText(find.byType(TextField), 'مُحَمَّد');
      expect(controller.text, equals(ArabicText.toSearchKey('مُحَمَّد')));
    });
  });

  group('ArabicNumberField', () {
    testWidgets('digitDirection western: eastern digits → western in field',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ArabicNumberField(
            controller: controller,
            digitDirection: ArabicDigitDirection.western,
          ),
        ),
      ));
      await tester.enterText(find.byType(TextField), '١٢٣');
      expect(controller.text, equals('123'));
    });

    testWidgets('digitDirection eastern: western digits → eastern in field',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ArabicNumberField(
            controller: controller,
            digitDirection: ArabicDigitDirection.eastern,
          ),
        ),
      ));
      await tester.enterText(find.byType(TextField), '123');
      expect(controller.text, equals('١٢٣'));
    });

    testWidgets('onNormalizedChanged always returns western digits',
        (tester) async {
      String? captured;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ArabicNumberField(
            digitDirection: ArabicDigitDirection.eastern,
            onNormalizedChanged: (v) => captured = v,
          ),
        ),
      ));
      await tester.enterText(find.byType(TextField), '123');
      // field shows ١٢٣ (eastern formatter applied), normalized always western
      expect(captured, equals('123'));
    });

    testWidgets('defaults to TextDirection.ltr', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ArabicNumberField()),
      ));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.textDirection, equals(TextDirection.ltr));
    });

    testWidgets('defaults to TextAlign.left', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ArabicNumberField()),
      ));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.textAlign, equals(TextAlign.left));
    });

    testWidgets('textDirection and textAlign can be overridden',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ArabicNumberField(
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
        ),
      ));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.textDirection, equals(TextDirection.rtl));
      expect(tf.textAlign, equals(TextAlign.right));
    });
  });
}
