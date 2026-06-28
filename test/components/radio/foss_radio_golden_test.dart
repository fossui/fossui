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

/// The radio sweeps its resting states: unselected, selected, selected with a
/// description, invalid, and disabled. Focus, RTL, and tap targets are covered
/// by the widget tests; the golden locks the static appearance.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'unselected',
    child: themed(
      data,
      const SizedBox(
        width: 200,
        child: FossRadioGroup<String>(
          children: [
            FossRadio(value: 'a', label: 'Monthly'),
            FossRadio(value: 'b', label: 'Yearly'),
          ],
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'selected',
    child: themed(
      data,
      const SizedBox(
        width: 200,
        child: FossRadioGroup<String>(
          groupValue: 'a',
          children: [
            FossRadio(value: 'a', label: 'Monthly'),
            FossRadio(value: 'b', label: 'Yearly'),
          ],
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'description',
    child: themed(
      data,
      const SizedBox(
        width: 200,
        child: FossRadioGroup<String>(
          groupValue: 'a',
          label: 'Billing',
          children: [
            FossRadio(
              value: 'a',
              label: 'Monthly',
              description: 'Billed monthly',
            ),
            FossRadio(value: 'b', label: 'Yearly', description: 'Save 16%'),
          ],
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'error',
    child: themed(
      data,
      const SizedBox(
        width: 200,
        child: FossRadioGroup<String>(
          errorText: 'Pick a plan',
          children: [
            FossRadio(value: 'a', label: 'Monthly'),
            FossRadio(value: 'b', label: 'Yearly'),
          ],
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'disabled',
    child: themed(
      data,
      const SizedBox(
        width: 200,
        child: FossRadioGroup<String>(
          groupValue: 'a',
          enabled: false,
          children: [
            FossRadio(value: 'a', label: 'Monthly'),
            FossRadio(value: 'b', label: 'Yearly'),
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
        child: FossRadioGroup<String>(
          variant: FossRadioGroupVariant.card,
          groupValue: 'a',
          children: [
            FossRadio(
              value: 'a',
              label: 'Email',
              description: 'Notify by email',
            ),
            FossRadio(value: 'b', label: 'SMS', description: 'Notify by text'),
          ],
        ),
      ),
    ),
  ),
];

void main() {
  goldenTest(
    'radio (light)',
    fileName: 'radio',
    builder: () =>
        GoldenTestGroup(columns: 6, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'radio (dark)',
    fileName: 'radio_dark',
    builder: () =>
        GoldenTestGroup(columns: 6, children: _scenarios(FossThemeData.dark)),
  );
}
