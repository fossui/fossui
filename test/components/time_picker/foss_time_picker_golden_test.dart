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

Widget _field(Widget child) => SizedBox(width: 280, child: child);

// The closed trigger sweeps its resting appearance: empty, filled in both hour
// formats, and disabled. The open sheet, the wheels, and the keyboard are
// covered by the widget tests, which can drive a route; a golden cell has no
// navigator to push one onto.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'empty',
    child: themed(
      data,
      _field(FossTimePicker(value: null, onChanged: (_) {})),
    ),
  ),
  GoldenTestScenario(
    name: 'filled-12h',
    child: themed(
      data,
      _field(
        FossTimePicker(
          value: const FossTimeOfDay(hour: 9, minute: 30),
          onChanged: (_) {},
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'filled-24h',
    child: themed(
      data,
      _field(
        FossTimePicker(
          value: const FossTimeOfDay(hour: 21, minute: 30),
          onChanged: (_) {},
          use24HourFormat: true,
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'disabled',
    child: themed(
      data,
      _field(
        FossTimePicker(
          value: const FossTimeOfDay(hour: 9, minute: 30),
          onChanged: (_) {},
          enabled: false,
        ),
      ),
    ),
  ),
];

void main() {
  goldenTest(
    'time picker (light)',
    fileName: 'time_picker',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'time picker (dark)',
    fileName: 'time_picker_dark',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.dark)),
  );
}
