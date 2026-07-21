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

// A fixed frame so the bottom-anchored panel lays out deterministically; the
// panel hugs its content height and sticks to the bottom edge. FossDrawer reads
// its side from context and defaults to bottom with no scope, so it renders as
// a bottom sheet here without a route.
Widget _frame(Widget child) => SizedBox(width: 320, height: 360, child: child);

/// Sweeps the bottom-sheet surface: the exposed rounded corners, the collapsing
/// header-to-body seam, the bare and filled footers, the drag handle, and the
/// square-cornered straight variant.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'bare footer',
    child: themed(
      data,
      _frame(
        const FossDrawer(
          title: Text('Filters'),
          description: Text('Narrow the results.'),
          content: Text('A short body of drawer content.'),
          actions: [Text('Apply')],
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'filled footer',
    child: themed(
      data,
      _frame(
        const FossDrawer(
          title: Text('Filters'),
          content: Text('A short body of drawer content.'),
          footerVariant: FossDrawerFooterVariant.filled,
          actions: [Text('Apply')],
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'handle',
    child: themed(
      data,
      _frame(
        const FossDrawer(
          showHandle: true,
          title: Text('Filters'),
          content: Text('A short body of drawer content.'),
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'straight',
    child: themed(
      data,
      _frame(
        const FossDrawer(
          variant: FossDrawerVariant.straight,
          title: Text('Filters'),
          content: Text('A short body of drawer content.'),
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'scroll fade',
    child: themed(
      data,
      _frame(
        FossDrawer(
          title: const Text('Terms'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              20,
              (i) => Text('Line ${i + 1} of the scrollable body.'),
            ),
          ),
        ),
      ),
    ),
  ),
];

void main() {
  goldenTest(
    'drawer (light)',
    fileName: 'drawer',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'drawer (dark)',
    fileName: 'drawer_dark',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.dark)),
  );
}
