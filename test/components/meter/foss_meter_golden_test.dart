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

// A fixed width so the track and its fraction fill lay out deterministically,
// with animations disabled so the fill rests at its value for the capture.
Widget _gauge(FossMeter meter) => MediaQuery(
  data: const MediaQueryData(disableAnimations: true),
  child: SizedBox(width: 260, child: meter),
);

/// Sweeps the surface the paint owns: the empty, partial, and full fills, the
/// `radii.full` superellipse pill, the label / value row, a bare track, and a
/// custom range with a unit formatter.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'empty',
    child: themed(data, _gauge(const FossMeter(value: 0, label: 'Storage'))),
  ),
  GoldenTestScenario(
    name: 'partial',
    child: themed(data, _gauge(const FossMeter(value: 40, label: 'Storage'))),
  ),
  GoldenTestScenario(
    name: 'full',
    child: themed(data, _gauge(const FossMeter(value: 100, label: 'Storage'))),
  ),
  GoldenTestScenario(
    name: 'bare',
    child: themed(
      data,
      _gauge(const FossMeter(value: 60, showValue: false)),
    ),
  ),
  GoldenTestScenario(
    name: 'formatted',
    child: themed(
      data,
      _gauge(
        FossMeter(
          value: 2.4,
          max: 8,
          label: 'Disk',
          formatValue: (value, min, max) => '$value GB',
        ),
      ),
    ),
  ),
];

void main() {
  goldenTest(
    'meter (light)',
    fileName: 'meter',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'meter (dark)',
    fileName: 'meter_dark',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.dark)),
  );
}
