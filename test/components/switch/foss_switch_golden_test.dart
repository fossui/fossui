@Tags(['golden'])
library;

// goldenTest registers a test and returns a future it manages itself, like
// testWidgets; the calls are intentionally not awaited.
// ignore_for_file: discarded_futures

import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import '../../support/golden_matrix.dart';

void _noop(bool _) {}

/// The switch sweeps its resting states: off and on, each enabled and disabled.
/// The track crossfade, thumb shadow, and pill are pinned; focus, drag, and the
/// press squish are covered by the widget tests.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'off',
    child: themed(data, FossSwitch(value: false, onChanged: _noop)),
  ),
  GoldenTestScenario(
    name: 'on',
    child: themed(data, FossSwitch(value: true, onChanged: _noop)),
  ),
  GoldenTestScenario(
    name: 'off disabled',
    child: themed(data, const FossSwitch(value: false)),
  ),
  GoldenTestScenario(
    name: 'on disabled',
    child: themed(data, const FossSwitch(value: true)),
  ),
];

void main() {
  goldenTest(
    'switch (light)',
    fileName: 'switch',
    builder: () =>
        GoldenTestGroup(columns: 4, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'switch (dark)',
    fileName: 'switch_dark',
    builder: () =>
        GoldenTestGroup(columns: 4, children: _scenarios(FossThemeData.dark)),
  );
}
