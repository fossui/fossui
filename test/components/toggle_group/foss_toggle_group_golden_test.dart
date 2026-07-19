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

void _noopSingle(String? _) {}
void _noopMultiple(Set<String> _) {}

const _items = [
  FossToggleGroupItem(value: 'left', child: Text('Left')),
  FossToggleGroupItem(value: 'center', child: Text('Center')),
  FossToggleGroupItem(value: 'right', child: Text('Right')),
];

/// The group sweeps the two layouts that change how items join: the standard
/// variant sits as separate buttons with a gap, the outline variant fuses into
/// one segmented bar with shared borders and rounded outer ends. Each is shown
/// with a live single selection, plus the multiple, vertical, and disabled
/// looks. Hover and focus are covered by the widget tests.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'standard single',
    child: themed(
      data,
      FossToggleGroup.single(
        value: 'center',
        onChanged: _noopSingle,
        children: _items,
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'outline single',
    child: themed(
      data,
      FossToggleGroup.single(
        value: 'center',
        variant: FossToggleVariant.outline,
        onChanged: _noopSingle,
        children: _items,
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'outline multiple',
    child: themed(
      data,
      FossToggleGroup.multiple(
        value: const {'left', 'right'},
        variant: FossToggleVariant.outline,
        onChanged: _noopMultiple,
        children: _items,
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'outline vertical',
    child: themed(
      data,
      FossToggleGroup.single(
        value: 'center',
        variant: FossToggleVariant.outline,
        orientation: Axis.vertical,
        onChanged: _noopSingle,
        children: _items,
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'disabled',
    child: themed(
      data,
      FossToggleGroup.single(
        value: 'center',
        variant: FossToggleVariant.outline,
        enabled: false,
        onChanged: _noopSingle,
        children: _items,
      ),
    ),
  ),
];

void main() {
  goldenTest(
    'toggle group (light)',
    fileName: 'toggle_group',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'toggle group (dark)',
    fileName: 'toggle_group_dark',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.dark)),
  );
}
