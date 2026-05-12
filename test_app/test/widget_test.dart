import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_libraries_test_app/main.dart';

void main() {
  testWidgets('App smoke test — home screen renders', (tester) async {
    await tester.pumpWidget(const ArabicTestApp());
    await tester.pumpAndSettle();
    expect(find.text('اختيار الشاشة'), findsNothing);
    expect(find.text('اختر الشاشة'), findsOneWidget);
  });
}
