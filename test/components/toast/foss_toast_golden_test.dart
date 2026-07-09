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

// A duration long enough that the auto-dismiss timer never fires during the
// pump, so each surface stays put for the capture.
const _persist = Duration(minutes: 10);

// One scenario per cell. Only the frontmost toast renders its content, so each
// type gets its own toaster; the last cell stacks three to pin the pile's peek,
// scale, and darkened rear surfaces.
const _specs = <(String, List<FossToast>)>[
  ('normal', [FossToast(title: Text('Message sent'), duration: _persist)]),
  (
    'info',
    [
      FossToast(
        type: FossToastType.info,
        title: Text('Link copied'),
        duration: _persist,
      ),
    ],
  ),
  (
    'success',
    [
      FossToast(
        type: FossToastType.success,
        title: Text('Changes saved'),
        description: Text('Your draft is up to date.'),
        action: _Undo(),
        duration: _persist,
      ),
    ],
  ),
  (
    'error',
    [
      FossToast(
        type: FossToastType.error,
        title: Text('Upload failed'),
        description: Text('The file is larger than 10 MB.'),
        duration: _persist,
      ),
    ],
  ),
  (
    'loading',
    [FossToast(type: FossToastType.loading, title: Text('Uploading'))],
  ),
  (
    'pile',
    [
      FossToast(title: Text('First'), duration: _persist),
      FossToast(title: Text('Second'), duration: _persist),
      FossToast(title: Text('Third'), duration: _persist),
    ],
  ),
];

class _Undo extends StatelessWidget {
  const _Undo();

  @override
  Widget build(BuildContext context) => FossButton(
    variant: FossButtonVariant.ghost,
    size: FossButtonSize.sm,
    onPressed: () {},
    child: const Text('Undo'),
  );
}

List<GoldenTestScenario> _scenarios(FossThemeData data) => [
  for (final (name, _) in _specs)
    GoldenTestScenario(
      name: name,
      child: themed(
        data,
        MediaQuery(
          // Skip the enter animation so the surface lands in its resting spot.
          data: const MediaQueryData(disableAnimations: true),
          child: SizedBox(
            width: 320,
            height: 150,
            child: FossToaster(
              child: ColoredBox(key: Key(name), color: data.colors.background),
            ),
          ),
        ),
      ),
    ),
];

Future<void> _populate(WidgetTester tester) async {
  for (final (name, toasts) in _specs) {
    final context = tester.element(find.byKey(Key(name)));
    for (final toast in toasts) {
      showFossToast(context, toast);
    }
  }
  await tester.pumpAndSettle();
}

void main() {
  goldenTest(
    'toast (light)',
    fileName: 'toast',
    pumpBeforeTest: _populate,
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.light)),
  );

  goldenTest(
    'toast (dark)',
    fileName: 'toast_dark',
    pumpBeforeTest: _populate,
    builder: () =>
        GoldenTestGroup(columns: 2, children: _scenarios(FossThemeData.dark)),
  );
}
