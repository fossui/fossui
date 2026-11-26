import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

/// The fill behind the highlighted row, read off the row's decoration, so the
/// tests assert what the user sees rather than a private index.
Color? _fillOf(WidgetTester tester, String label) {
  final box = tester.widget<DecoratedBox>(
    find
        .ancestor(of: find.text(label), matching: find.byType(DecoratedBox))
        .first,
  );
  return (box.decoration as ShapeDecoration).color;
}

bool _highlighted(WidgetTester tester, String label) =>
    _fillOf(tester, label) != null;

void main() {
  const highlight = FossThemeData.light;

  group('FossMenu keyboard', () {
    Future<void> open(
      WidgetTester tester, {
      List<FossMenuItem>? items,
      void Function(String label)? onSelected,
    }) async {
      await tester.pumpWidget(
        host(
          FossMenu(
            items:
                items ??
                [
                  FossMenuItem(
                    label: 'First',
                    onSelected: () => onSelected?.call('First'),
                  ),
                  FossMenuItem(
                    label: 'Second',
                    onSelected: () => onSelected?.call('Second'),
                  ),
                  FossMenuItem(
                    label: 'Third',
                    onSelected: () => onSelected?.call('Third'),
                  ),
                ],
            child: menuTrigger,
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('the panel opens with no row highlighted', (tester) async {
      await open(tester);

      expect(_highlighted(tester, 'First'), isFalse);
      expect(_highlighted(tester, 'Second'), isFalse);
    });

    testWidgets('ArrowDown lands on the first row, then walks down', (
      tester,
    ) async {
      await open(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_fillOf(tester, 'First'), highlight.colors.accent);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_highlighted(tester, 'First'), isFalse);
      expect(_highlighted(tester, 'Second'), isTrue);
    });

    testWidgets('ArrowUp lands on the last row from nothing', (tester) async {
      await open(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(_highlighted(tester, 'Third'), isTrue);
    });

    testWidgets('the walk wraps at both ends', (tester) async {
      await open(tester);

      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      }
      await tester.pump();
      expect(_highlighted(tester, 'Third'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_highlighted(tester, 'First'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(_highlighted(tester, 'Third'), isTrue);
    });

    testWidgets('the walk skips disabled rows and keeps inert ones', (
      tester,
    ) async {
      await open(
        tester,
        items: const [
          FossMenuItem(label: 'First'),
          FossMenuItem(label: 'Blocked', enabled: false),
          FossMenuItem(label: 'Third'),
        ],
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_highlighted(tester, 'First'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_highlighted(tester, 'Blocked'), isFalse);
      expect(_highlighted(tester, 'Third'), isTrue);
    });

    testWidgets('the walk skips separators and headings', (tester) async {
      await open(
        tester,
        items: const [
          FossMenuItem.label('Actions'),
          FossMenuItem(label: 'First'),
          FossMenuItem.separator(),
          FossMenuItem(label: 'Third'),
        ],
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_highlighted(tester, 'First'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_highlighted(tester, 'Third'), isTrue);
    });

    testWidgets('Enter selects the highlighted row', (tester) async {
      final picked = <String>[];
      await open(tester, onSelected: picked.add);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(picked, ['Second']);
      expect(find.text('Second'), findsNothing);
    });

    testWidgets('Space selects the highlighted row', (tester) async {
      final picked = <String>[];
      await open(tester, onSelected: picked.add);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(picked, ['First']);
    });

    testWidgets('Enter with nothing highlighted selects nothing', (
      tester,
    ) async {
      final picked = <String>[];
      await open(tester, onSelected: picked.add);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(picked, isEmpty);
      expect(find.text('First'), findsOneWidget);
    });

    testWidgets('Escape closes the panel', (tester) async {
      await open(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('First'), findsNothing);
    });

    testWidgets('a hover moves the highlight', (tester) async {
      await open(tester);

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('Second'))),
      );
      await tester.pump();

      expect(_highlighted(tester, 'Second'), isTrue);
      expect(_highlighted(tester, 'First'), isFalse);
    });

    testWidgets('a hover does not highlight a disabled row', (tester) async {
      await open(
        tester,
        items: const [
          FossMenuItem(label: 'First'),
          FossMenuItem(label: 'Blocked', enabled: false),
        ],
      );

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('Blocked'))),
      );
      await tester.pump();

      expect(_highlighted(tester, 'Blocked'), isFalse);
    });

    testWidgets('a key over a list with nothing selectable does nothing', (
      tester,
    ) async {
      await open(
        tester,
        items: const [
          FossMenuItem.label('Actions'),
          FossMenuItem.separator(),
        ],
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('Actions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
