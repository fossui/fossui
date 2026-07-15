import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

void main() {
  test('keeps the version it was constructed with', () {
    // A runtime string keeps the const constructor from folding at build time.
    final version = '0.2.0'.substring(0);
    final since = FossSince(version);
    expect(since.version, '0.2.0');
  });
}
