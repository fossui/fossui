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

/// One row at a fixed width, so a cell pins the slot layout rather than the
/// intrinsic width of its text.
Widget _tile({
  FossListTileVariant variant = FossListTileVariant.filled,
  bool leading = false,
  bool subtitle = false,
  bool trailing = false,
  bool enabled = true,
  bool tappable = true,
}) => SizedBox(
  width: 320,
  child: FossListTile(
    variant: variant,
    leading: leading ? const _Dot() : null,
    title: const Text('Notifications'),
    subtitle: subtitle ? const Text('Push and email') : null,
    trailing: trailing ? const _Dot() : null,
    enabled: enabled,
    onTap: tappable ? () {} : null,
  ),
);

/// Every slot combination plus the inert and disabled rows, so the golden pins
/// the gaps that collapse, the one-line and two-line heights, and the dim. The
/// last pair pins the plain variant against the filled surface above it.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(name: 'title', child: themed(data, _tile())),
  GoldenTestScenario(
    name: 'leading',
    child: themed(data, _tile(leading: true)),
  ),
  GoldenTestScenario(
    name: 'subtitle',
    child: themed(data, _tile(subtitle: true)),
  ),
  GoldenTestScenario(
    name: 'trailing',
    child: themed(data, _tile(trailing: true)),
  ),
  GoldenTestScenario(
    name: 'every slot',
    child: themed(
      data,
      _tile(leading: true, subtitle: true, trailing: true),
    ),
  ),
  GoldenTestScenario(
    name: 'inert',
    child: themed(
      data,
      _tile(leading: true, subtitle: true, tappable: false),
    ),
  ),
  GoldenTestScenario(
    name: 'disabled',
    child: themed(
      data,
      _tile(leading: true, subtitle: true, trailing: true, enabled: false),
    ),
  ),
  GoldenTestScenario(
    name: 'plain',
    child: themed(
      data,
      _tile(
        variant: FossListTileVariant.plain,
        leading: true,
        subtitle: true,
        trailing: true,
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'stacked',
    child: themed(
      data,
      Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          _tile(leading: true, trailing: true),
          _tile(leading: true, subtitle: true, trailing: true),
        ],
      ),
    ),
  ),
];

void main() {
  goldenTest(
    'list tile (light)',
    fileName: 'list_tile',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'list tile (dark)',
    fileName: 'list_tile_dark',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.dark)),
  );
}

/// A stand-in slot mark, so the golden exercises the leading and trailing slots
/// without pulling in an icon dependency.
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
