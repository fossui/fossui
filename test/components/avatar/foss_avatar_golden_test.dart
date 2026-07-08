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

/// The fallback face across the size scale, plus a bare background circle.
/// Image loading is asynchronous and covered by the widget tests; the golden
/// locks the circle geometry and the fallback type step per size.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'sizes',
    child: themed(
      data,
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          for (final size in FossAvatarSize.values)
            FossAvatar(size: size, fallback: const Text('VL')),
        ],
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'empty',
    child: themed(data, const FossAvatar()),
  ),
];

void main() {
  goldenTest(
    'avatar (light)',
    fileName: 'avatar',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'avatar (dark)',
    fileName: 'avatar_dark',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.dark)),
  );
}
