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

/// The resting looks the variant by size sweep does not reach: the disabled
/// dim, the square icon-only shape, a leading and trailing pair, and a `style`
/// override. Loading is omitted here (its spinner animates) and is covered by
/// the widget tests.
List<GoldenTestScenario> _stateScenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'disabled',
    child: themed(data, const FossButton(child: Text('Disabled'))),
  ),
  GoldenTestScenario(
    name: 'icon only',
    child: themed(
      data,
      FossButton.icon(
        onPressed: () {},
        semanticLabel: 'Add',
        icon: const Text('+'),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'leading trailing',
    child: themed(
      data,
      FossButton(
        onPressed: () {},
        variant: FossButtonVariant.outline,
        leading: const Text('<'),
        trailing: const Text('>'),
        child: const Text('Nav'),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'styled',
    child: themed(
      data,
      FossButton(
        onPressed: () {},
        style: const FossButtonStyle(
          borderRadius: 999,
          backgroundColor: WidgetStatePropertyAll(Color(0xFF6D28D9)),
        ),
        child: const Text('Pill'),
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

  goldenTest(
    'button states (light)',
    fileName: 'button_states',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: _stateScenarios(FossThemeData.light),
    ),
  );

  goldenTest(
    'button states (dark)',
    fileName: 'button_states_dark',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: _stateScenarios(FossThemeData.dark),
    ),
  );
}
