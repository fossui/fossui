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

const List<FossComboboxItem<String>> _items = [
  FossComboboxItem(value: 'us', label: 'United States'),
  FossComboboxItem(value: 'ca', label: 'Canada'),
  FossComboboxItem(value: 'mx', label: 'Mexico'),
];

Widget _frame(Widget child) => SizedBox(width: 260, child: child);

/// The resting closed field: empty, a chosen value, and the error affordance.
/// The open popup is an overlay driven by focus and is covered by the widget
/// tests; the golden pins the collapsed trigger.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'empty',
    child: themed(
      data,
      _frame(
        const FossCombobox<String>(
          items: _items,
          label: 'Country',
          hintText: 'Select a country',
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'selected',
    child: themed(
      data,
      _frame(
        const FossCombobox<String>(
          items: _items,
          value: 'ca',
          label: 'Country',
          showClear: true,
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'error',
    child: themed(
      data,
      _frame(
        const FossCombobox<String>(
          items: _items,
          label: 'Country',
          hintText: 'Select a country',
          errorText: 'Pick a country',
        ),
      ),
    ),
  ),
];

void main() {
  goldenTest(
    'combobox (light)',
    fileName: 'combobox',
    builder: () =>
        GoldenTestGroup(columns: 1, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'combobox (dark)',
    fileName: 'combobox_dark',
    builder: () =>
        GoldenTestGroup(columns: 1, children: _scenarios(FossThemeData.dark)),
  );
}
