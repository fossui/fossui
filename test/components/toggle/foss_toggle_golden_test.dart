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

void _noop(bool _) {}

/// The toggle sweeps variant x size at rest (off), the two axes that change its
/// shape and fill. Hover, focus, and the press feedback are covered by the
/// widget tests; the golden locks the resting look of every variant at every
/// size.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  for (final variant in FossToggleVariant.values)
    for (final size in FossToggleSize.values)
      GoldenTestScenario(
        name: '${variant.name} ${size.name}',
        child: themed(
          data,
          FossToggle(
            pressed: false,
            variant: variant,
            size: size,
            onPressedChanged: _noop,
            child: const Text('Bold'),
          ),
        ),
      ),
];

/// The resting looks the variant by size sweep does not reach: the on
/// (pressed) fill for each variant, the disabled dim, and the square icon-only
/// shape.
List<GoldenTestScenario> _stateScenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'standard on',
    child: themed(
      data,
      FossToggle(
        pressed: true,
        onPressedChanged: _noop,
        child: const Text('Bold'),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'outline on',
    child: themed(
      data,
      FossToggle(
        pressed: true,
        variant: FossToggleVariant.outline,
        onPressedChanged: _noop,
        child: const Text('Bold'),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'disabled',
    child: themed(
      data,
      const FossToggle(pressed: true, child: Text('Bold')),
    ),
  ),
  GoldenTestScenario(
    name: 'icon only',
    child: themed(
      data,
      FossToggle(
        pressed: false,
        variant: FossToggleVariant.outline,
        semanticLabel: 'Bold',
        onPressedChanged: _noop,
        leading: const Text('B'),
      ),
    ),
  ),
];

void main() {
  goldenTest(
    'toggle (light)',
    fileName: 'toggle',
    builder: () => GoldenTestGroup(
      columns: 3,
      children: [
        ..._scenarios(FossThemeData.light),
        ..._stateScenarios(FossThemeData.light),
      ],
    ),
  );

  goldenTest(
    'toggle (dark)',
    fileName: 'toggle_dark',
    builder: () => GoldenTestGroup(
      columns: 3,
      children: [
        ..._scenarios(FossThemeData.dark),
        ..._stateScenarios(FossThemeData.dark),
      ],
    ),
  );
}
