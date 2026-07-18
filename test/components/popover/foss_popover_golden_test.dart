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

const _triggerKey = Key('popover-trigger');

Widget _content(BuildContext context) {
  final t = context.fossTheme;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Dimensions',
        style: t.typography.sm.medium.copyWith(
          color: t.colors.popoverForeground,
        ),
      ),
      SizedBox(height: t.spacing(1)),
      Text(
        'Set the panel width and height.',
        style: t.typography.sm.copyWith(color: t.colors.mutedForeground),
      ),
    ],
  );
}

Widget _host(FossThemeData data, {bool modal = false}) => themed(
  data,
  SizedBox(
    width: 260,
    height: 220,
    child: Center(
      child: FossPopover(
        modal: modal,
        builder: _content,
        child: DecoratedBox(
          key: _triggerKey,
          decoration: BoxDecoration(
            color: data.colors.secondary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const SizedBox(width: 96, height: 32),
        ),
      ),
    ),
  ),
);

// Tap the trigger and settle so the surface is on screen when the frame is
// captured.
Future<void> _openPopover(WidgetTester tester) async {
  await tester.tap(find.byKey(_triggerKey));
  await tester.pumpAndSettle();
}

void main() {
  goldenTest(
    'popover (light)',
    fileName: 'popover',
    pumpBeforeTest: _openPopover,
    builder: () => _host(FossThemeData.light),
  );

  goldenTest(
    'popover (dark)',
    fileName: 'popover_dark',
    pumpBeforeTest: _openPopover,
    builder: () => _host(FossThemeData.dark),
  );

  goldenTest(
    'popover modal (light)',
    fileName: 'popover_modal',
    pumpBeforeTest: _openPopover,
    builder: () => _host(FossThemeData.light, modal: true),
  );

  goldenTest(
    'popover modal (dark)',
    fileName: 'popover_modal_dark',
    pumpBeforeTest: _openPopover,
    builder: () => _host(FossThemeData.dark, modal: true),
  );
}
