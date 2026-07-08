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

const List<FossTab<String>> _tabs = [
  FossTab(value: 'account', label: 'Account'),
  FossTab(value: 'billing', label: 'Billing'),
  FossTab(value: 'team', label: 'Team'),
];

Widget _frame(Widget child) => SizedBox(width: 300, child: child);

/// The two bar variants in their resting state with the first tab active, plus
/// a disabled tab. The golden pins the segmented pill and the underline
/// indicator; selection and keyboard motion are covered by the widget tests.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'segmented',
    child: themed(
      data,
      _frame(
        const FossTabs<String>(tabs: _tabs, value: 'account'),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'underline',
    child: themed(
      data,
      _frame(
        const FossTabs<String>(
          tabs: _tabs,
          value: 'account',
          variant: FossTabsVariant.underline,
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'disabled',
    child: themed(
      data,
      _frame(
        const FossTabs<String>(
          tabs: [
            FossTab(value: 'account', label: 'Account'),
            FossTab(value: 'billing', label: 'Billing', enabled: false),
            FossTab(value: 'team', label: 'Team'),
          ],
          value: 'account',
        ),
      ),
    ),
  ),
];

void main() {
  goldenTest(
    'tabs (light)',
    fileName: 'tabs',
    builder: () =>
        GoldenTestGroup(columns: 1, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'tabs (dark)',
    fileName: 'tabs_dark',
    builder: () =>
        GoldenTestGroup(columns: 1, children: _scenarios(FossThemeData.dark)),
  );
}
