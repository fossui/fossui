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

const _surfaceKey = Key('toast-surface');

// A duration long enough that the auto-dismiss timer never fires during the
// pump, so the stack stays put for the capture.
const _persist = Duration(minutes: 10);

Widget _host(FossThemeData data) => themed(
  data,
  MediaQuery(
    // Skip the enter animation so the stack lands in its resting position.
    data: const MediaQueryData(size: Size(360, 260), disableAnimations: true),
    child: SizedBox(
      width: 360,
      height: 260,
      child: FossToaster(
        child: ColoredBox(
          key: _surfaceKey,
          color: data.colors.background,
        ),
      ),
    ),
  ),
);

// Enqueue one toast per accent so the golden pins the surface, the leading
// glyph, and the action affordance across types.
Future<void> _showToasts(WidgetTester tester) async {
  final context = tester.element(find.byKey(_surfaceKey));
  showFossToast(
    context,
    const FossToast(
      type: FossToastType.info,
      title: Text('Link copied'),
      duration: _persist,
    ),
  );
  showFossToast(
    context,
    FossToast(
      type: FossToastType.success,
      title: const Text('Changes saved'),
      description: const Text('Your draft is up to date.'),
      action: FossButton(
        variant: FossButtonVariant.ghost,
        size: FossButtonSize.sm,
        onPressed: () {},
        child: const Text('Undo'),
      ),
      duration: _persist,
    ),
  );
  showFossToast(
    context,
    const FossToast(
      type: FossToastType.error,
      title: Text('Upload failed'),
      description: Text('The file is larger than 10 MB.'),
      duration: _persist,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  goldenTest(
    'toast (light)',
    fileName: 'toast',
    pumpBeforeTest: _showToasts,
    builder: () => _host(FossThemeData.light),
  );

  goldenTest(
    'toast (dark)',
    fileName: 'toast_dark',
    pumpBeforeTest: _showToasts,
    builder: () => _host(FossThemeData.dark),
  );
}
