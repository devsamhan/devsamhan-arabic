import 'package:arabic_text/arabic_text.dart';
import 'package:test/test.dart';

void main() {
  test('SPEC_VERSION is the 1.0.1 clarification', () {
    expect(ArabicText.specVersion, '1.0.1');
  });
}
