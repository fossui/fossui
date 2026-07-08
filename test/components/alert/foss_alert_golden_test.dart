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

Widget _frame(Widget child) => SizedBox(width: 320, child: child);

/// One cell per variant so the golden pins each accent, fill, border, and
/// default glyph, plus a title-only row and a row with trailing actions.
List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  for (final variant in FossAlertVariant.values)
    GoldenTestScenario(
      name: variant.name,
      child: themed(
        data,
        _frame(
          FossAlert(
            variant: variant,
            title: const Text('Heads up'),
            description: const Text('Something worth a glance happened.'),
          ),
        ),
      ),
    ),
  GoldenTestScenario(
    name: 'title only',
    child: themed(
      data,
      _frame(
        const FossAlert(
          variant: FossAlertVariant.info,
          title: Text('Saved to drafts'),
        ),
      ),
    ),
  ),
  GoldenTestScenario(
    name: 'actions',
    child: themed(
      data,
      _frame(
        FossAlert(
          variant: FossAlertVariant.error,
          title: const Text('Payment failed'),
          description: const Text('Update the card on file to continue.'),
          actions: [
            FossButton(
              variant: FossButtonVariant.ghost,
              size: FossButtonSize.sm,
              onPressed: () {},
              child: const Text('Dismiss'),
            ),
            FossButton(
              size: FossButtonSize.sm,
              onPressed: () {},
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    ),
  ),
];

void main() {
  goldenTest(
    'alert (light)',
    fileName: 'alert',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'alert (dark)',
    fileName: 'alert_dark',
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.dark)),
  );
}
