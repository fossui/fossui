@Tags(['golden'])
library;

// goldenTest registers a test and returns a future it manages itself, like
// testWidgets; the calls are intentionally not awaited.
// ignore_for_file: discarded_futures

import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

import '../../support/golden_matrix.dart';

/// The button sweeps variant x size, the two axes that change its look. State,
/// direction, and textScale are exercised by the widget tests; the golden locks
/// the resting appearance of every variant at every size.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  for (final variant in FossButtonVariant.values)
    for (final size in FossButtonSize.values)
      GoldenTestScenario(
        name: '${variant.name} ${size.name}',
        child: themed(
          data,
          FossButton(
            onPressed: () {},
            variant: variant,
            size: size,
            child: const Text('Continue'),
          ),
        ),
      ),
];

void main() {
  goldenTest(
    'button (light)',
    fileName: 'button',
    builder: () => GoldenTestGroup(
      columns: 3,
      children: _scenarios(FossThemeData.light),
    ),
  );

  goldenTest(
    'button (dark)',
    fileName: 'button_dark',
    builder: () => GoldenTestGroup(
      columns: 3,
      children: _scenarios(FossThemeData.dark),
    ),
  );
}
