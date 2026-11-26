@Tags(['golden'])
library;

// goldenTest registers a test and returns a future it manages itself, like
// testWidgets; the calls are intentionally not awaited.
// ignore_for_file: discarded_futures

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import '../../support/golden_matrix.dart';

const _triggerKey = Key('menu-trigger');

final List<FossMenuItem> _items = [
  const FossMenuItem.label('Actions'),
  FossMenuItem(
    label: 'New file',
    icon: const Icon(Icons.insert_drive_file_outlined),
    shortcut: 'Ctrl N',
    onSelected: () {},
  ),
  FossMenuItem(
    label: 'Duplicate',
    icon: const Icon(Icons.copy_outlined),
    shortcut: 'Ctrl D',
    onSelected: () {},
  ),
  FossMenuItem(label: 'Rename', inset: true, onSelected: () {}),
  const FossMenuItem.separator(),
  const FossMenuItem(label: 'Move to archive', enabled: false),
  const FossMenuItem(label: 'Export as PDF'),
  FossMenuItem(
    label: 'Delete',
    icon: const Icon(Icons.delete_outline),
    destructive: true,
    onSelected: () {},
  ),
];

/// The trigger sits at the top start of a roomy cell, so the panel opens
/// downward with room to spare and the capture frames the whole surface.
Widget _host(FossThemeData data, {TextDirection? direction}) {
  Widget cell = SizedBox(
    width: 320,
    height: 380,
    child: Align(
      alignment: AlignmentDirectional.topStart,
      child: FossMenu(
        items: _items,
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
  );
  if (direction != null) {
    cell = Directionality(textDirection: direction, child: cell);
  }
  return themed(data, cell);
}

/// Taps the trigger and settles, so the panel is on screen when the frame is
/// captured.
Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(_triggerKey));
  await tester.pumpAndSettle();
}

/// Opens the panel and walks the highlight onto the second action row, which
/// is what pins the highlight fill and its foreground.
Future<void> _openHighlighted(WidgetTester tester) async {
  await _open(tester);
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  await tester.pumpAndSettle();
}

void main() {
  goldenTest(
    'menu (light)',
    fileName: 'menu',
    pumpBeforeTest: _open,
    builder: () => _host(FossThemeData.light),
  );

  goldenTest(
    'menu (dark)',
    fileName: 'menu_dark',
    pumpBeforeTest: _open,
    builder: () => _host(FossThemeData.dark),
  );

  goldenTest(
    'menu highlighted (light)',
    fileName: 'menu_highlighted',
    pumpBeforeTest: _openHighlighted,
    builder: () => _host(FossThemeData.light),
  );

  goldenTest(
    'menu highlighted (dark)',
    fileName: 'menu_highlighted_dark',
    pumpBeforeTest: _openHighlighted,
    builder: () => _host(FossThemeData.dark),
  );

  goldenTest(
    'menu right to left (light)',
    fileName: 'menu_rtl',
    pumpBeforeTest: _open,
    builder: () => _host(FossThemeData.light, direction: TextDirection.rtl),
  );

  goldenTest(
    'menu closed trigger (light)',
    fileName: 'menu_closed',
    builder: () => _host(FossThemeData.light),
  );
}
