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

const _triggerKey = Key('tooltip-trigger');

Widget _host(FossThemeData data) => themed(
  data,
  SizedBox(
    width: 200,
    height: 120,
    child: Center(
      child: FossTooltip(
        message: 'Copy link',
        child: DecoratedBox(
          key: _triggerKey,
          decoration: BoxDecoration(
            color: data.colors.secondary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const SizedBox(width: 72, height: 32),
        ),
      ),
    ),
  ),
);

// Long-press the trigger and wait out the show delay so the bubble is on screen
// when the frame is captured.
Future<void> _openTooltip(WidgetTester tester) async {
  await tester.longPress(find.byKey(_triggerKey));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

void main() {
  goldenTest(
    'tooltip (light)',
    fileName: 'tooltip',
    pumpBeforeTest: _openTooltip,
    builder: () => _host(FossThemeData.light),
  );

  goldenTest(
    'tooltip (dark)',
    fileName: 'tooltip_dark',
    pumpBeforeTest: _openTooltip,
    builder: () => _host(FossThemeData.dark),
  );
}
