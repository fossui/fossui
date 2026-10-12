import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';
import 'package:fossui/src/foundation/anchored_overlay.dart';

import 'host.dart';

/// Every side and align the public API offers, each resolved through the
/// directional-to-physical mapping and its right-to-left mirror. The panel
/// rectangle is read off the inner ring, which fills the surface.
void main() {
  final items = [FossMenuItem(label: 'New file', onSelected: () {})];

  Future<Rect> open(
    WidgetTester tester, {
    FossMenuSide side = FossMenuSide.bottom,
    FossMenuAlign align = FossMenuAlign.start,
    TextDirection direction = TextDirection.ltr,
    Alignment alignment = Alignment.center,
  }) async {
    await tester.pumpWidget(
      host(
        FossMenu(
          items: items,
          side: side,
          align: align,
          child: menuTrigger,
        ),
        direction: direction,
        alignment: alignment,
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return tester.getRect(find.byType(OverlayInnerRing));
  }

  group('FossMenu placement', () {
    testWidgets('the top side opens above the trigger', (tester) async {
      final panel = await open(tester, side: FossMenuSide.top);
      final trigger = tester.getRect(find.text('Open'));

      expect(panel.bottom, lessThanOrEqualTo(trigger.top));
    });

    testWidgets('the left side opens before the trigger', (tester) async {
      final panel = await open(tester, side: FossMenuSide.left);
      final trigger = tester.getRect(find.text('Open'));

      expect(panel.right, lessThanOrEqualTo(trigger.left));
    });

    testWidgets('the right side opens after the trigger', (tester) async {
      final panel = await open(tester, side: FossMenuSide.right);
      final trigger = tester.getRect(find.text('Open'));

      expect(panel.left, greaterThanOrEqualTo(trigger.right));
    });

    testWidgets('the left side mirrors to the right under RTL', (tester) async {
      final panel = await open(
        tester,
        side: FossMenuSide.left,
        direction: TextDirection.rtl,
      );
      final trigger = tester.getRect(find.text('Open'));

      expect(panel.left, greaterThanOrEqualTo(trigger.right));
    });

    testWidgets('the right side mirrors to the left under RTL', (
      tester,
    ) async {
      final panel = await open(
        tester,
        side: FossMenuSide.right,
        direction: TextDirection.rtl,
      );
      final trigger = tester.getRect(find.text('Open'));

      expect(panel.right, lessThanOrEqualTo(trigger.left));
    });

    testWidgets('the center align centers the panel on the trigger', (
      tester,
    ) async {
      final panel = await open(tester, align: FossMenuAlign.center);
      final trigger = tester.getRect(find.text('Open'));

      expect(panel.center.dx, closeTo(trigger.center.dx, 0.5));
    });

    testWidgets('the end align hangs the panel off the trigger end', (
      tester,
    ) async {
      final panel = await open(tester, align: FossMenuAlign.end);
      final trigger = tester.getRect(find.text('Open'));

      expect(panel.right, closeTo(trigger.right, 0.5));
    });

    testWidgets('the end align mirrors to the start edge under RTL', (
      tester,
    ) async {
      final panel = await open(
        tester,
        align: FossMenuAlign.end,
        direction: TextDirection.rtl,
      );
      final trigger = tester.getRect(find.text('Open'));

      expect(panel.left, closeTo(trigger.left, 0.5));
    });

    testWidgets('the center align is unmirrored under RTL', (tester) async {
      final panel = await open(
        tester,
        align: FossMenuAlign.center,
        direction: TextDirection.rtl,
      );
      final trigger = tester.getRect(find.text('Open'));

      expect(panel.center.dx, closeTo(trigger.center.dx, 0.5));
    });
  });

  group('FossMenu dismissal', () {
    testWidgets('reduced motion closes the panel on the same frame', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossMenu(items: items, child: menuTrigger),
          reduceMotion: true,
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      expect(find.text('New file'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(find.text('New file'), findsNothing);
    });

    // The barrier covers the page while the panel is open, so a touch drag
    // never reaches the list underneath. What this guards is a scroll the app
    // drives itself, or one already in flight when the panel opened.
    testWidgets('a scroll under the open panel closes it', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        host(
          ListView(
            controller: controller,
            children: [
              const SizedBox(height: 40),
              FossMenu(items: items, child: menuTrigger),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('New file'), findsOneWidget);

      controller.jumpTo(80);
      await tester.pumpAndSettle();

      expect(find.text('New file'), findsNothing);
    });

    testWidgets('a closed menu leaves no scroll listener behind', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        host(
          ListView(
            controller: controller,
            children: [
              FossMenu(items: items, child: menuTrigger),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // The listener comes off on close, so a later scroll is inert rather
      // than a second close against a panel that is already gone.
      controller.jumpTo(80);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a shorter list drops a highlight past its end', (
      tester,
    ) async {
      final long = [
        for (var i = 0; i < 3; i++)
          FossMenuItem(label: 'Row $i', onSelected: () {}),
      ];
      final short = [long.first];

      Widget build(List<FossMenuItem> rows) => rebuildableHost(
        FossMenu(items: rows, child: menuTrigger),
      );

      await tester.pumpWidget(build(long));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      await tester.pumpWidget(build(short));
      await tester.pumpAndSettle();

      expect(find.text('Row 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('FossMenuController', () {
    testWidgets('a trigger that eats the tap still opens through toggle', (
      tester,
    ) async {
      final controller = FossMenuController();

      var taps = 0;

      await tester.pumpWidget(
        host(
          FossMenu(
            items: items,
            controller: controller,
            child: _Trigger(onTap: () => taps++),
          ),
        ),
      );

      // The trigger consumes the gesture, so the menu's own detector never
      // sees it and nothing opens. That is the case the controller exists for.
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(find.text('New file'), findsNothing);
      expect(controller.isOpen, isFalse);

      controller.toggle();
      await tester.pumpAndSettle();
      expect(find.text('New file'), findsOneWidget);
      expect(controller.isOpen, isTrue);

      controller.toggle();
      await tester.pumpAndSettle();
      expect(find.text('New file'), findsNothing);
    });

    testWidgets('open and close are idempotent', (tester) async {
      final controller = FossMenuController();

      await tester.pumpWidget(
        host(
          FossMenu(items: items, controller: controller, child: menuTrigger),
        ),
      );

      controller.close();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);

      controller
        ..open()
        ..open();
      await tester.pumpAndSettle();
      expect(find.text('New file'), findsOneWidget);

      controller.close();
      await tester.pumpAndSettle();
      expect(find.text('New file'), findsNothing);
    });

    testWidgets('a detached controller is inert', (tester) async {
      final controller = FossMenuController();

      await tester.pumpWidget(
        rebuildableHost(
          FossMenu(items: items, controller: controller, child: menuTrigger),
        ),
      );
      await tester.pumpWidget(
        rebuildableHost(FossMenu(items: items, child: menuTrigger)),
      );
      await tester.pumpAndSettle();

      controller.open();
      await tester.pumpAndSettle();

      expect(controller.isOpen, isFalse);
      expect(find.text('New file'), findsNothing);
    });

    testWidgets('swapping controllers moves the handle', (tester) async {
      final first = FossMenuController();
      final second = FossMenuController();

      Widget build(FossMenuController controller) => rebuildableHost(
        FossMenu(items: items, controller: controller, child: menuTrigger),
      );

      await tester.pumpWidget(build(first));
      await tester.pumpWidget(build(second));
      await tester.pumpAndSettle();

      first.open();
      await tester.pumpAndSettle();
      expect(find.text('New file'), findsNothing);

      second.open();
      await tester.pumpAndSettle();
      expect(find.text('New file'), findsOneWidget);
    });
  });
}

/// A trigger that handles its own tap, the shape a `FossButton` with an
/// `onPressed` takes: the gesture never reaches the menu.
class _Trigger extends StatelessWidget {
  const _Trigger({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: const Text('Open'),
  );
}
