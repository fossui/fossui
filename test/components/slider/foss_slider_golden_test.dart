@Tags(['golden'])
library;

// goldenTest registers a test and returns a future it manages itself, like
// testWidgets; the calls are intentionally not awaited.
// ignore_for_file: discarded_futures

import 'package:alchemist/alchemist.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import '../../support/golden_matrix.dart';

void _noop(double _) {}

// A fixed box so the track, filled range, and thumb travel lay out
// deterministically; the height is pinned too because the golden group lays the
// cells out in a Table, which asks for intrinsics the slider's LayoutBuilder
// cannot supply.
Widget _sized(Widget child) =>
    SizedBox(width: 220, height: 56, child: Center(child: child));

/// Sweeps the resting surface the paint owns: the filled range at the two ends
/// and the middle, the disabled dim, and a style override on the track. The
/// focus ring, the shadow drop, and the drag scale are transient and covered by
/// the widget tests, with one focused cell below.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'min',
    child: themed(data, _sized(FossSlider(value: 0, onChanged: _noop))),
  ),
  GoldenTestScenario(
    name: 'mid',
    child: themed(data, _sized(FossSlider(value: 50, onChanged: _noop))),
  ),
  GoldenTestScenario(
    name: 'max',
    child: themed(data, _sized(FossSlider(value: 100, onChanged: _noop))),
  ),
  GoldenTestScenario(
    name: 'disabled',
    child: themed(data, _sized(const FossSlider(value: 50, onChanged: null))),
  ),
  GoldenTestScenario(
    name: 'styled',
    child: themed(
      data,
      _sized(
        FossSlider(
          value: 60,
          onChanged: _noop,
          style: const FossSliderStyle(
            rangeColor: Color(0xFF8A38F5),
            trackHeight: 6,
            thumbSize: 24,
          ),
        ),
      ),
    ),
  ),
];

Future<void> _focusThumb(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();
}

void main() {
  goldenTest(
    'slider (light)',
    fileName: 'slider',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'slider (dark)',
    fileName: 'slider_dark',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.dark)),
  );

  // A single focused slider pins the keyboard focus ring and its light/dark
  // alpha, the resting shadow and rim dropped behind it.
  goldenTest(
    'slider focused (light)',
    fileName: 'slider_focused',
    pumpBeforeTest: _focusThumb,
    builder: () => themed(
      FossThemeData.light,
      _sized(FossSlider(value: 50, onChanged: _noop)),
    ),
  );

  goldenTest(
    'slider focused (dark)',
    fileName: 'slider_focused_dark',
    pumpBeforeTest: _focusThumb,
    builder: () => themed(
      FossThemeData.dark,
      _sized(FossSlider(value: 50, onChanged: _noop)),
    ),
  );
}
