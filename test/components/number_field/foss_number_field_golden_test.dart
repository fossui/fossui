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

/// Sweeps size x state, the axes that change the resting look. Focus, hover,
/// RTL, and textScale are exercised by the widget tests; the golden locks the
/// empty, filled, at-bound (increment dimmed), error, and disabled appearance
/// at every size.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  for (final size in FossTextFieldSize.values) ...[
    GoldenTestScenario(
      name: '${size.name} empty',
      child: themed(
        data,
        SizedBox(
          width: 160,
          child: FossNumberField(size: size, placeholder: '0'),
        ),
      ),
    ),
    GoldenTestScenario(
      name: '${size.name} filled',
      child: themed(
        data,
        SizedBox(width: 160, child: FossNumberField(size: size, value: 3)),
      ),
    ),
    GoldenTestScenario(
      name: '${size.name} at max',
      child: themed(
        data,
        SizedBox(
          width: 160,
          child: FossNumberField(size: size, value: 10, max: 10),
        ),
      ),
    ),
    GoldenTestScenario(
      name: '${size.name} error',
      child: themed(
        data,
        SizedBox(
          width: 160,
          child: FossNumberField(size: size, value: 3, error: true),
        ),
      ),
    ),
    GoldenTestScenario(
      name: '${size.name} disabled',
      child: themed(
        data,
        SizedBox(
          width: 160,
          child: FossNumberField(size: size, value: 3, enabled: false),
        ),
      ),
    ),
  ],
];

void main() {
  goldenTest(
    'number field (light)',
    fileName: 'number_field',
    builder: () => GoldenTestGroup(
      columns: 5,
      children: _scenarios(FossThemeData.light),
    ),
  );

  goldenTest(
    'number field (dark)',
    fileName: 'number_field_dark',
    builder: () => GoldenTestGroup(
      columns: 5,
      children: _scenarios(FossThemeData.dark),
    ),
  );
}
