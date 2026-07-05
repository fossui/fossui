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

// A fixed frame so the centered card and the bottom sheet both lay out
// deterministically: the card floats in the middle, the sheet sticks to the
// bottom edge.
Widget _frame(Widget child) => SizedBox(width: 360, height: 620, child: child);

List<Widget> _actions() => [
  FossButton(
    variant: FossButtonVariant.ghost,
    onPressed: () {},
    child: const Text('Cancel'),
  ),
  FossButton(onPressed: () {}, child: const Text('Delete')),
];

// Sweeps the layout paths the surface owns: the two presentations, the bare and
// filled footers, a headerless scrolling body, and the alert's centered header.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  GoldenTestScenario(
    name: 'card filled',
    child: themed(
      data,
      _frame(
        FossDialog(
          presentation: FossDialogPresentation.centered,
          title: const Text('Delete project'),
          description: const Text('This permanently removes the project.'),
          actions: _actions(),
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'card bare',
    child: themed(
      data,
      _frame(
        FossDialog(
          presentation: FossDialogPresentation.centered,
          footerVariant: FossDialogFooterVariant.bare,
          title: const Text('Delete project'),
          description: const Text('This permanently removes the project.'),
          actions: _actions(),
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'card headerless',
    child: themed(
      data,
      _frame(
        FossDialog(
          presentation: FossDialogPresentation.centered,
          content: const Text('A body with no header above it.'),
          actions: [
            FossButton(onPressed: () {}, child: const Text('Accept')),
          ],
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'sheet filled',
    child: themed(
      data,
      _frame(
        FossDialog(
          presentation: FossDialogPresentation.bottomSheet,
          title: const Text('Delete project'),
          description: const Text('This permanently removes the project.'),
          actions: _actions(),
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'sheet bare',
    child: themed(
      data,
      _frame(
        FossDialog(
          presentation: FossDialogPresentation.bottomSheet,
          footerVariant: FossDialogFooterVariant.bare,
          title: const Text('Delete project'),
          description: const Text('This permanently removes the project.'),
          actions: _actions(),
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'alert',
    child: themed(
      data,
      _frame(
        FossAlertDialog(
          title: const Text('Session expired'),
          description: const Text('Sign in again to continue.'),
          actions: [
            FossButton(onPressed: () {}, child: const Text('Sign in')),
          ],
        ),
      ),
    ),
  ),
];

void main() {
  goldenTest(
    'dialog (light)',
    fileName: 'dialog',
    builder: () =>
        GoldenTestGroup(columns: 3, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'dialog (dark)',
    fileName: 'dialog_dark',
    builder: () =>
        GoldenTestGroup(columns: 3, children: _scenarios(FossThemeData.dark)),
  );
}
