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

/// A row of both sizes for one variant in one state, so a cell pins the size
/// pair and the state together.
Widget _row(
  FossChipVariant variant, {
  bool selected = false,
  bool enabled = true,
  bool leading = false,
  bool removable = false,
}) => Row(
  mainAxisSize: MainAxisSize.min,
  spacing: 8,
  children: [
    for (final size in FossChipSize.values)
      FossChip(
        label: const Text('Design'),
        variant: variant,
        size: size,
        selected: selected,
        enabled: enabled,
        leading: leading ? const _Dot() : null,
        onSelected: (_) {},
        onRemove: removable ? () {} : null,
      ),
  ],
);

/// Every variant at rest, selected, and disabled, plus the two slot
/// combinations, so the golden pins the fills, the primary selection pill, the
/// close affordance, and the superellipse corners.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  for (final variant in FossChipVariant.values) ...[
    GoldenTestScenario(
      name: '${variant.name} rest',
      child: themed(data, _row(variant)),
    ),
    GoldenTestScenario(
      name: '${variant.name} selected',
      child: themed(data, _row(variant, selected: true)),
    ),
    GoldenTestScenario(
      name: '${variant.name} disabled',
      child: themed(data, _row(variant, enabled: false)),
    ),
    GoldenTestScenario(
      name: '${variant.name} removable',
      child: themed(data, _row(variant, removable: true)),
    ),
    GoldenTestScenario(
      name: '${variant.name} leading',
      child: themed(data, _row(variant, leading: true, removable: true)),
    ),
  ],
];

void main() {
  goldenTest(
    'chip (light)',
    fileName: 'chip',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'chip (dark)',
    fileName: 'chip_dark',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.dark)),
  );
}

/// A stand-in leading mark, so the golden exercises the slot without pulling in
/// an icon dependency.
class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    final size = IconTheme.of(context).size ?? 16;
    final color = IconTheme.of(context).color;
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: SizedBox.square(
          dimension: size / 2,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: color,
              shape: const CircleBorder(),
            ),
          ),
        ),
      ),
    );
  }
}
