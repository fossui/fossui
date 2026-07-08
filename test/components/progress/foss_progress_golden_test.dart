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
Widget _bar(FossProgress progress) => MediaQuery(
  data: const MediaQueryData(disableAnimations: true),
  child: SizedBox(width: 260, child: progress),
);

/// Sweeps the surface the paint owns: the empty, partial, and full fills, the
/// `radii.full` superellipse pill, and the label row above the track.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'empty',
    child: themed(data, _bar(const FossProgress(value: 0))),
  ),
  GoldenTestScenario(
    name: 'partial',
    child: themed(data, _bar(const FossProgress(value: 0.4))),
  ),
  GoldenTestScenario(
    name: 'full',
    child: themed(data, _bar(const FossProgress(value: 1))),
  ),
  GoldenTestScenario(
    name: 'labelled',
    child: themed(
      data,
      _bar(
        const FossProgress(
          value: 0.6,
          label: 'Uploading',
          valueLabel: '60%',
        ),
      ),
    ),
  ),
];

void main() {
  goldenTest(
    'progress (light)',
    fileName: 'progress',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'progress (dark)',
    fileName: 'progress_dark',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.dark)),
  );
}
