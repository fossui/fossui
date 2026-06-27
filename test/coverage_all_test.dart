// Forces every library reachable from the public barrel into the coverage
// report. `flutter test --coverage` only instruments libraries a test imports,
// so an untested file would otherwise be absent from the report rather than
// shown at 0%, silently inflating the percentage. An internal library that the
// barrel does not export (and nothing exported imports) must be added here, or
// carry its own test, to stay visible.
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

void main() {
  test('public surface is reachable for coverage', () {
    expect(FossThemeData.light, isNotNull);
  });
}
