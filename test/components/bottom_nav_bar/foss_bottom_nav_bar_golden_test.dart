@Tags(['golden'])
library;

// goldenTest registers a test and returns a future it manages itself, like
// testWidgets; the calls are intentionally not awaited.
// ignore_for_file: discarded_futures

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import '../../support/golden_matrix.dart';

const _three = <FossBottomNavItem<String>>[
  FossBottomNavItem(
    value: 'home',
    label: 'Home',
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
  ),
  FossBottomNavItem(
    value: 'search',
    label: 'Search',
    icon: Icon(Icons.search),
  ),
  FossBottomNavItem(value: 'you', label: 'You', icon: Icon(Icons.person)),
];

const _five = <FossBottomNavItem<String>>[
  FossBottomNavItem(value: 'home', label: 'Home', icon: Icon(Icons.home)),
  FossBottomNavItem(
    value: 'inbox',
    label: 'Inbox',
    icon: Icon(Icons.mail),
    badge: FossBadge(size: FossBadgeSize.sm, label: Text('3')),
  ),
  FossBottomNavItem(value: 'saved', label: 'Saved', icon: Icon(Icons.bookmark)),
  FossBottomNavItem(
    value: 'team',
    label: 'Team',
    icon: Icon(Icons.group),
    enabled: false,
  ),
  FossBottomNavItem(value: 'you', label: 'You', icon: Icon(Icons.person)),
];

Widget _frame(Widget child) => SizedBox(width: 360, child: child);

/// The bar at three and five destinations, with a badge, a disabled cell, an
/// inert bar, and a right-to-left run. Selection color, the top hairline, and
/// the badge overhang are what the golden pins; taps and keyboard motion are
/// covered by the widget tests.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'three destinations',
    child: themed(
      data,
      _frame(
        FossBottomNavBar<String>(
          items: _three,
          value: 'home',
          onChanged: (_) {},
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'five with a badge and a disabled cell',
    child: themed(
      data,
      _frame(
        FossBottomNavBar<String>(
          items: _five,
          value: 'inbox',
          onChanged: (_) {},
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'inert',
    child: themed(
      data,
      _frame(const FossBottomNavBar<String>(items: _three, value: 'search')),
    ),
  ),
  GoldenTestScenario(
    name: 'right to left',
    child: themed(
      data,
      Directionality(
        textDirection: TextDirection.rtl,
        child: _frame(
          FossBottomNavBar<String>(
            items: _five,
            value: 'inbox',
            onChanged: (_) {},
          ),
        ),
      ),
    ),
  ),
];

void main() {
  goldenTest(
    'bottom nav bar (light)',
    fileName: 'bottom_nav_bar',
    builder: () =>
        GoldenTestGroup(columns: 1, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'bottom nav bar (dark)',
    fileName: 'bottom_nav_bar_dark',
    builder: () =>
        GoldenTestGroup(columns: 1, children: _scenarios(FossThemeData.dark)),
  );
}
