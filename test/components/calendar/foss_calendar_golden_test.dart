@Tags(['golden'])
library;

// goldenTest registers a test and returns a future it manages itself, like
// testWidgets; the calls are intentionally not awaited.
// ignore_for_file: discarded_futures

import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import '../../support/golden_matrix.dart';

final _march = DateTime(2026, 3);

// A fixed month with no today marker (the run date is elsewhere), so the grid
// is deterministic across runs.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'single',
    child: themed(
      data,
      FossCalendar.single(
        selected: DateTime(2026, 3, 15),
        onSelected: (_) {},
        initialMonth: _march,
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'range',
    child: themed(
      data,
      FossCalendar.range(
        selected: FossDateRange(
          start: DateTime(2026, 3, 10),
          end: DateTime(2026, 3, 20),
        ),
        onSelected: (_) {},
        initialMonth: _march,
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'bounds',
    child: themed(
      data,
      FossCalendar.single(
        selected: null,
        onSelected: (_) {},
        initialMonth: _march,
        minDate: DateTime(2026, 3, 10),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'no-outside',
    child: themed(
      data,
      FossCalendar.single(
        selected: null,
        onSelected: (_) {},
        initialMonth: _march,
        showOutsideDays: false,
      ),
    ),
  ),
];

void main() {
  goldenTest(
    'calendar (light)',
    fileName: 'calendar',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'calendar (dark)',
    fileName: 'calendar_dark',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.dark)),
  );
}
