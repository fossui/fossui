@Tags(['golden'])
library;

// goldenTest registers a test and returns a future it manages itself, like
// testWidgets; the calls are intentionally not awaited.
// ignore_for_file: discarded_futures

import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import '../../support/golden_matrix.dart';

/// The rule in both axes: a horizontal hairline splitting stacked content and a
/// vertical hairline splitting a row. The golden pins the 1 pixel weight and
/// the `border` color against the surface.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'horizontal',
    child: themed(
      data,
      const SizedBox(
        width: 180,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Above'),
            SizedBox(height: 12),
            FossSeparator(),
            SizedBox(height: 12),
            Text('Below'),
          ],
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'vertical',
    child: themed(
      data,
      const SizedBox(
        height: 40,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Left'),
            SizedBox(width: 12),
            FossSeparator(orientation: FossSeparatorOrientation.vertical),
            SizedBox(width: 12),
            Text('Right'),
          ],
        ),
      ),
    ),
  ),
];

void main() {
  goldenTest(
    'separator (light)',
    fileName: 'separator',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'separator (dark)',
    fileName: 'separator_dark',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.dark)),
  );
}
