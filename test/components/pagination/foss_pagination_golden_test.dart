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

/// A fixed cell, so every scenario resolves the same sibling count no matter
/// how the group lays its columns out. The size is tight in both axes because
/// the group asks its cells for intrinsic dimensions, which a width-sensitive
/// row cannot answer.
const Size _cell = Size(640, 56);

Widget _row(
  int page,
  int pageCount, {
  int siblingCount = 1,
  bool live = true,
  TextDirection direction = TextDirection.ltr,
  FossPaginationStyle? style,
}) => Directionality(
  textDirection: direction,
  child: SizedBox.fromSize(
    size: _cell,
    child: Center(
      child: FossPagination(
        page: page,
        pageCount: pageCount,
        siblingCount: siblingCount,
        style: style,
        onPageChanged: live ? (_) {} : null,
      ),
    ),
  ),
);

/// The windowing table plus the ends, the two other sibling counts, the inert
/// row, and RTL, so a cell pins both the layout and the state it renders.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(name: 'every page', child: themed(data, _row(3, 5))),
  GoldenTestScenario(name: 'threshold', child: themed(data, _row(4, 7))),
  GoldenTestScenario(name: 'first', child: themed(data, _row(1, 10))),
  GoldenTestScenario(name: 'near start', child: themed(data, _row(3, 10))),
  GoldenTestScenario(name: 'middle', child: themed(data, _row(5, 10))),
  GoldenTestScenario(name: 'near end', child: themed(data, _row(9, 10))),
  GoldenTestScenario(name: 'last', child: themed(data, _row(10, 10))),
  GoldenTestScenario(name: 'single page', child: themed(data, _row(1, 1))),
  GoldenTestScenario(
    name: 'sibling 0',
    child: themed(data, _row(5, 10, siblingCount: 0)),
  ),
  GoldenTestScenario(
    name: 'sibling 2',
    child: themed(data, _row(10, 20, siblingCount: 2)),
  ),
  GoldenTestScenario(
    name: 'inert',
    child: themed(data, _row(5, 10, live: false)),
  ),
  GoldenTestScenario(
    name: 'rtl',
    child: themed(data, _row(5, 10, direction: TextDirection.rtl)),
  ),
  // A filled active variant flips the button's foreground, so this cell is what
  // catches a page number painted in the plain foreground role: it would be
  // invisible against its own fill.
  GoldenTestScenario(
    name: 'filled active variant',
    child: themed(
      data,
      _row(
        5,
        20,
        style: const FossPaginationStyle(
          activeVariant: FossButtonVariant.primary,
          inactiveVariant: FossButtonVariant.secondary,
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'narrowed ellipsis',
    child: themed(
      data,
      _row(5, 20, style: const FossPaginationStyle(gap: 2, ellipsisWidth: 28)),
    ),
  ),
];

void main() {
  goldenTest(
    'pagination (light)',
    fileName: 'pagination',
    builder: () =>
        GoldenTestGroup(columns: 1, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'pagination (dark)',
    fileName: 'pagination_dark',
    builder: () =>
        GoldenTestGroup(columns: 1, children: _scenarios(FossThemeData.dark)),
  );
}
