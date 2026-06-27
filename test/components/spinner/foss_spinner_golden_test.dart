@Tags(['golden'])
library;

// goldenTest registers a test and returns a future it manages itself, like
// testWidgets; the calls are intentionally not awaited.
// ignore_for_file: discarded_futures

import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

import '../../support/golden_matrix.dart';

/// The spinner sweeps size x color x theme. State, direction, and textScale are
/// dropped: it has no interactive state, no text, and no directional layout.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  for (final size in const [16.0, 24.0, 32.0, 48.0])
    GoldenTestScenario(
      name: 'size $size',
      child: themed(data, FossSpinner(size: size)),
    ),
  GoldenTestScenario(
    name: 'primary',
    child: themed(data, FossSpinner(size: 32, color: data.colors.primary)),
  ),
  GoldenTestScenario(
    name: 'destructive',
    child: themed(data, FossSpinner(size: 32, color: data.colors.destructive)),
  ),
  GoldenTestScenario(
    name: 'muted',
    child: themed(
      data,
      FossSpinner(size: 32, color: data.colors.mutedForeground),
    ),
  ),
];

// Spinner never settles, so the default settle-based pump would hang. Pump a
// single frame to capture turn 0, a deterministic point in the loop.
Future<void> _pumpOneFrame(WidgetTester tester) => tester.pump();

void main() {
  goldenTest(
    'spinner (light)',
    fileName: 'spinner',
    pumpBeforeTest: _pumpOneFrame,
    builder: () => GoldenTestGroup(
      columns: 4,
      children: _scenarios(FossThemeData.light),
    ),
  );

  goldenTest(
    'spinner (dark)',
    fileName: 'spinner_dark',
    pumpBeforeTest: _pumpOneFrame,
    builder: () => GoldenTestGroup(
      columns: 4,
      children: _scenarios(FossThemeData.dark),
    ),
  );
}
