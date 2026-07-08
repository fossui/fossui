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

Widget _sized(Widget child) => SizedBox(width: 300, child: child);

/// Sweeps the slot combinations the seams and surface own: the full card, a
/// header over content, lone content, and a header over a footer with no
/// content between them (both pads stay at the full inset). Pins the surface,
/// the superellipse corners, the inner rim flip, and the collapsing paddings.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'full',
    child: themed(
      data,
      _sized(
        const FossCard(
          title: Text('Project'),
          description: Text('Manage your settings.'),
          action: Text('Add'),
          content: Text('A short body of card content.'),
          footer: Text('Footer'),
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'header and content',
    child: themed(
      data,
      _sized(
        const FossCard(
          title: Text('Project'),
          description: Text('Manage your settings.'),
          content: Text('A short body of card content.'),
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'content only',
    child: themed(
      data,
      _sized(const FossCard(content: Text('A short body of card content.'))),
    ),
  ),
  GoldenTestScenario(
    name: 'header and footer',
    child: themed(
      data,
      _sized(
        const FossCard(title: Text('Project'), footer: Text('Footer')),
      ),
    ),
  ),
];

void main() {
  goldenTest(
    'card (light)',
    fileName: 'card',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'card (dark)',
    fileName: 'card_dark',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.dark)),
  );
}
