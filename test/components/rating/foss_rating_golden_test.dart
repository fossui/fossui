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

/// Sweeps the resting surface the paint owns: the fill at both ends and part
/// way through, the three sizes, the read-only and disabled rows, a custom icon
/// pair, and a style override. The focus ring is transient and gets its own
/// cell below.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'empty',
    child: themed(data, const FossRating(value: 0)),
  ),
  GoldenTestScenario(
    name: 'partial',
    child: themed(data, const FossRating(value: 3)),
  ),
  GoldenTestScenario(
    name: 'half',
    child: themed(data, const FossRating(value: 3.5)),
  ),
  GoldenTestScenario(
    name: 'average',
    child: themed(data, const FossRating(value: 4.3)),
  ),
  GoldenTestScenario(
    name: 'full',
    child: themed(data, const FossRating(value: 5)),
  ),
  GoldenTestScenario(
    name: 'sm',
    child: themed(data, const FossRating(value: 3.5, size: FossRatingSize.sm)),
  ),
  GoldenTestScenario(
    name: 'lg',
    child: themed(data, const FossRating(value: 3.5, size: FossRatingSize.lg)),
  ),
  GoldenTestScenario(
    name: 'interactive',
    child: themed(data, const FossRating(value: 3, onChanged: _noop)),
  ),
  GoldenTestScenario(
    name: 'disabled',
    child: themed(
      data,
      const FossRating(value: 3, enabled: false, onChanged: _noop),
    ),
  ),
  GoldenTestScenario(
    name: 'count 3',
    child: themed(data, const FossRating(value: 1.5, count: 3)),
  ),
  GoldenTestScenario(
    name: 'custom icons',
    child: themed(
      data,
      const FossRating(
        value: 2.5,
        emptyIcon: Text('o'),
        filledIcon: Text('x'),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'styled',
    child: themed(
      data,
      const FossRating(
        value: 3.5,
        style: FossRatingStyle(
          filledColor: Color(0xFFF59E0B),
          glyphSize: 28,
          gap: 8,
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'rtl half',
    child: themed(
      data,
      const Directionality(
        textDirection: TextDirection.rtl,
        child: FossRating(value: 3.5),
      ),
    ),
  ),
];

Future<void> _focusRow(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();
}

void main() {
  goldenTest(
    'rating (light)',
    fileName: 'rating',
    builder: () =>
        GoldenTestGroup(columns: 3, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'rating (dark)',
    fileName: 'rating_dark',
    builder: () =>
        GoldenTestGroup(columns: 3, children: _scenarios(FossThemeData.dark)),
  );

  // One focused row pins the keyboard ring drawn around the whole control.
  goldenTest(
    'rating focused (light)',
    fileName: 'rating_focused',
    pumpBeforeTest: _focusRow,
    builder: () => themed(
      FossThemeData.light,
      const FossRating(value: 3, onChanged: _noop),
    ),
  );

  goldenTest(
    'rating focused (dark)',
    fileName: 'rating_focused_dark',
    pumpBeforeTest: _focusRow,
    builder: () => themed(
      FossThemeData.dark,
      const FossRating(value: 3, onChanged: _noop),
    ),
  );
}
