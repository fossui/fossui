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

/// The checkbox sweeps its resting states: unchecked, checked, indeterminate,
/// checked with a description, invalid, disabled, and the card group. Focus,
/// RTL, and tap targets are covered by the widget tests; the golden locks the
/// static appearance.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'unchecked',
    child: themed(data, const FossCheckbox(label: 'Notify me')),
  ),
  GoldenTestScenario(
    name: 'checked',
    child: themed(data, const FossCheckbox(value: true, label: 'Notify me')),
  ),
  GoldenTestScenario(
    name: 'indeterminate',
    child: themed(data, const FossCheckbox(value: null, label: 'Notify me')),
  ),
  GoldenTestScenario(
    name: 'description',
    child: themed(
      data,
      const SizedBox(
        width: 220,
        child: FossCheckbox(
          value: true,
          label: 'Email',
          description: 'Notify by email',
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'error',
    child: themed(
      data,
      const FossCheckbox(
        label: 'Accept terms',
        errorText: 'This field is required',
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'disabled',
    child: themed(
      data,
      const FossCheckbox(value: true, label: 'Notify me', enabled: false),
    ),
  ),
  GoldenTestScenario(
    name: 'group',
    child: themed(
      data,
      const SizedBox(
        width: 220,
        child: FossCheckboxGroup<String>(
          label: 'Frameworks',
          values: {'next'},
          children: [
            FossCheckboxItem(value: 'next', label: 'Next.js'),
            FossCheckboxItem(value: 'vite', label: 'Vite'),
          ],
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'card',
    child: themed(
      data,
      const SizedBox(
        width: 220,
        child: FossCheckboxGroup<String>(
          variant: FossCheckboxGroupVariant.card,
          values: {'next'},
          children: [
            FossCheckboxItem(
              value: 'next',
              label: 'Next.js',
              description: 'React framework',
            ),
            FossCheckboxItem(value: 'vite', label: 'Vite'),
          ],
        ),
      ),
    ),
  ),
];

void main() {
  goldenTest(
    'checkbox (light)',
    fileName: 'checkbox',
    builder: () =>
        GoldenTestGroup(columns: 4, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'checkbox (dark)',
    fileName: 'checkbox_dark',
    builder: () =>
        GoldenTestGroup(columns: 4, children: _scenarios(FossThemeData.dark)),
  );
}
