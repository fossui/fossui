import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';
import 'package:fossui/src/foundation/anchored_overlay.dart';

import 'host.dart';

void main() {
  group('FossMenu', () {
    testWidgets('the panel is closed until the trigger is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [FossMenuItem(label: 'New file', onSelected: () {})],
            child: menuTrigger,
          ),
        ),
      );

      expect(find.text('New file'), findsNothing);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('New file'), findsOneWidget);
    });

    testWidgets('a row runs its action and closes the panel', (tester) async {
      var picked = 0;
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [
              FossMenuItem(label: 'New file', onSelected: () => picked++),
            ],
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New file'));
      await tester.pumpAndSettle();

      expect(picked, 1);
      expect(find.text('New file'), findsNothing);
    });

    testWidgets('an inert row does nothing and leaves the panel open', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FossMenu(
            items: [FossMenuItem(label: 'Coming soon')],
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Coming soon'));
      await tester.pumpAndSettle();

      expect(find.text('Coming soon'), findsOneWidget);
    });

    testWidgets('a disabled row takes no tap', (tester) async {
      var picked = 0;
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [
              FossMenuItem(
                label: 'Blocked',
                enabled: false,
                onSelected: () => picked++,
              ),
            ],
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Blocked'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(picked, 0);
      expect(find.text('Blocked'), findsOneWidget);
    });

    testWidgets('a tap outside closes without firing anything', (tester) async {
      var picked = 0;
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [
              FossMenuItem(label: 'New file', onSelected: () => picked++),
            ],
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(700, 560));
      await tester.pumpAndSettle();

      expect(picked, 0);
      expect(find.text('New file'), findsNothing);
    });

    testWidgets('onOpenChange reports both edges', (tester) async {
      final changes = <bool>[];
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [FossMenuItem(label: 'New file', onSelected: () {})],
            onOpenChange: changes.add,
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New file'));
      await tester.pumpAndSettle();

      expect(changes, [true, false]);
    });

    testWidgets('a separator and a heading render and take no input', (
      tester,
    ) async {
      var picked = 0;
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [
              const FossMenuItem.label('Actions'),
              FossMenuItem(label: 'New file', onSelected: () => picked++),
              const FossMenuItem.separator(),
            ],
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Actions'), findsOneWidget);

      await tester.tap(find.text('Actions'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(picked, 0);
      expect(find.text('New file'), findsOneWidget);
    });

    testWidgets('a shortcut renders at the row end', (tester) async {
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [
              FossMenuItem(
                label: 'New file',
                shortcut: 'Ctrl N',
                onSelected: () {},
              ),
            ],
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final label = tester.getRect(find.text('New file'));
      final shortcut = tester.getRect(find.text('Ctrl N'));
      expect(shortcut.left, greaterThan(label.left));
    });

    testWidgets('a destructive row reads the destructive role', (tester) async {
      const theme = FossThemeData.light;
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [
              FossMenuItem(
                label: 'Delete',
                destructive: true,
                onSelected: () {},
              ),
            ],
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('Delete'));
      expect(text.style?.color, theme.colors.destructiveForeground);
    });

    testWidgets('the panel hugs its widest row above the minimum width', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FossMenu(
            items: [FossMenuItem(label: 'Hi')],
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final panel = tester.getRect(find.byType(OverlayInnerRing));
      expect(panel.width, 128);
      expect(panel.width, lessThan(400));
    });

    testWidgets('a long list scrolls inside the panel', (tester) async {
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [
              for (var i = 0; i < 40; i++)
                FossMenuItem(label: 'Row $i', onSelected: () {}),
            ],
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final panel = tester.getRect(find.byType(OverlayInnerRing));
      expect(panel.height, lessThan(600));

      // The rows all build (the panel is not a lazy list), so scrolling is
      // measured by where the last row sits, not by whether it exists.
      expect(
        tester.getRect(find.text('Row 39')).top,
        greaterThan(panel.bottom),
      );

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -1200),
      );
      await tester.pumpAndSettle();

      expect(tester.getRect(find.text('Row 39')).top, lessThan(panel.bottom));
    });

    testWidgets('the panel flips above a trigger with no room below', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [FossMenuItem(label: 'New file', onSelected: () {})],
            child: menuTrigger,
          ),
          alignment: Alignment.bottomLeft,
        ),
      );

      final trigger = tester.getRect(find.text('Open'));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final panel = tester.getRect(find.byType(OverlayInnerRing));
      expect(panel.bottom, lessThanOrEqualTo(trigger.top));
    });

    testWidgets('the panel opens below and flush with the trigger start', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [FossMenuItem(label: 'New file', onSelected: () {})],
            child: menuTrigger,
          ),
        ),
      );

      final trigger = tester.getRect(find.text('Open'));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final panel = tester.getRect(find.byType(OverlayInnerRing));
      expect(panel.top, trigger.bottom + 4);
      expect(panel.left, trigger.left);
    });

    testWidgets('under RTL the panel is flush with the trigger end', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [FossMenuItem(label: 'New file', onSelected: () {})],
            child: menuTrigger,
          ),
          direction: TextDirection.rtl,
          alignment: Alignment.topRight,
        ),
      );

      final trigger = tester.getRect(find.text('Open'));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final panel = tester.getRect(find.byType(OverlayInnerRing));
      expect(panel.right, trigger.right);
    });

    testWidgets('rows grow with the text scale and the panel still clamps', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [
              for (var i = 0; i < 20; i++)
                FossMenuItem(label: 'Row $i', onSelected: () {}),
            ],
            child: menuTrigger,
          ),
          textScale: 2,
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final row = tester.getRect(find.text('Row 0'));
      expect(row.height, greaterThan(20));

      final panel = tester.getRect(find.byType(OverlayInnerRing));
      expect(panel.height, lessThan(600));
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion opens the panel without a transition', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [FossMenuItem(label: 'New file', onSelected: () {})],
            child: menuTrigger,
          ),
          reduceMotion: true,
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();

      final opacity = tester.widget<FadeTransition>(
        find.ancestor(
          of: find.text('New file'),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(opacity.opacity.value, 1);
    });

    testWidgets('a style override reaches the panel', (tester) async {
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [FossMenuItem(label: 'New file', onSelected: () {})],
            style: const FossMenuStyle(minWidth: 240),
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byType(OverlayInnerRing)).width, 240);
    });

    testWidgets('an empty list opens an empty panel without throwing', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const FossMenu(items: [], child: menuTrigger)),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  });
}
