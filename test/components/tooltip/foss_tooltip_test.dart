import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

void main() {
  const triggerKey = Key('trigger');
  const showDelay = Duration(milliseconds: 500);

  Widget host(
    Widget child, {
    FossThemeData? theme,
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    bool reduceMotion = false,
    Alignment alignment = Alignment.center,
  }) => FossTheme(
    data: theme ?? FossThemeData.light,
    child: Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(800, 600),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (_) => Align(alignment: alignment, child: child),
            ),
          ],
        ),
      ),
    ),
  );

  // An opaque box is hit-testable, so long-press and hover land on it.
  Widget triggerBox({Key? key}) => ColoredBox(
    key: key,
    color: const Color(0xFF3366FF),
    child: const SizedBox(width: 60, height: 30),
  );

  FossTooltip tooltip({
    String message = 'Copy',
    FossTooltipSide side = FossTooltipSide.top,
    Duration hideDelay = Duration.zero,
    Widget? child,
  }) => FossTooltip(
    message: message,
    side: side,
    hideDelay: hideDelay,
    child: child ?? triggerBox(key: triggerKey),
  );

  Finder popupText(String message) => find.descendant(
    of: find.byType(Overlay),
    matching: find.text(message),
  );

  // Hovers the pointer over [finder], returning the active gesture so the
  // caller can move it away to trigger exit.
  Future<TestGesture> hover(WidgetTester tester, Finder finder) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(finder));
    await tester.pump();
    return gesture;
  }

  // The popup surface: the one DecoratedBox in the overlay carrying a
  // ShapeDecoration (the inner ring uses a plain BoxDecoration).
  ShapeDecoration popupSurface(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(Overlay),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<ShapeDecoration>()
      .first;

  // The inner highlight ring: the overlay DecoratedBox with a BoxDecoration
  // whose border carries the raised edge.
  Border ringBorder(WidgetTester tester) {
    final borders = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(Overlay),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.border)
        .whereType<Border>();
    return borders.first;
  }

  group('FossTooltipStyle.merge', () {
    test('null other returns the receiver unchanged', () {
      const base = FossTooltipStyle(borderRadius: 12);
      expect(base.merge(null), same(base));
    });

    test('other overrides non-null fields, keeps the rest', () {
      const base = FossTooltipStyle(
        backgroundColor: Color(0xFF111111),
        borderRadius: 8,
      );
      const other = FossTooltipStyle(
        borderRadius: 16,
        foregroundColor: Color(0xFF222222),
      );
      final merged = base.merge(other);

      expect(merged.backgroundColor, const Color(0xFF111111));
      expect(merged.borderRadius, 16);
      expect(merged.foregroundColor, const Color(0xFF222222));
    });
  });

  group('triggers', () {
    testWidgets('shows on long-press after the show delay', (tester) async {
      await tester.pumpWidget(host(tooltip()));
      expect(popupText('Copy'), findsNothing);

      await tester.longPress(find.byKey(triggerKey));
      await tester.pump();
      expect(
        popupText('Copy'),
        findsNothing,
        reason: 'still within show delay',
      );

      await tester.pump(showDelay);
      await tester.pumpAndSettle();
      expect(popupText('Copy'), findsOneWidget);
    });

    testWidgets('shows on hover and hides on exit', (tester) async {
      await tester.pumpWidget(host(tooltip()));

      final gesture = await hover(tester, find.byKey(triggerKey));
      await tester.pump(showDelay);
      await tester.pumpAndSettle();
      expect(popupText('Copy'), findsOneWidget);

      await gesture.moveTo(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect(popupText('Copy'), findsNothing);
    });

    testWidgets('shows on focus and hides on blur', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(
          tooltip(
            child: Focus(
              focusNode: node,
              child: const SizedBox(width: 60, height: 30),
            ),
          ),
        ),
      );

      node.requestFocus();
      await tester.pump(showDelay);
      await tester.pumpAndSettle();
      expect(popupText('Copy'), findsOneWidget);

      node.unfocus();
      await tester.pumpAndSettle();
      expect(popupText('Copy'), findsNothing);
    });
  });

  group('dismiss', () {
    testWidgets('Escape closes the open tooltip', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(
          tooltip(
            child: Focus(
              focusNode: node,
              child: const SizedBox(width: 60, height: 30),
            ),
          ),
        ),
      );

      node.requestFocus();
      await tester.pump(showDelay);
      await tester.pumpAndSettle();
      expect(popupText('Copy'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(popupText('Copy'), findsNothing);
    });

    testWidgets('hides only after the hide delay elapses', (tester) async {
      await tester.pumpWidget(
        host(tooltip(hideDelay: const Duration(milliseconds: 300))),
      );

      final gesture = await hover(tester, find.byKey(triggerKey));
      await tester.pump(showDelay);
      await tester.pumpAndSettle();
      expect(popupText('Copy'), findsOneWidget);

      await gesture.moveTo(const Offset(1, 1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        popupText('Copy'),
        findsOneWidget,
        reason: 'still within hide delay',
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(popupText('Copy'), findsNothing);
    });
  });

  group('positioning', () {
    testWidgets('opens above the anchor on the default top side', (
      tester,
    ) async {
      await tester.pumpWidget(host(tooltip()));

      await tester.longPress(find.byKey(triggerKey));
      await tester.pump(showDelay);
      await tester.pumpAndSettle();

      final anchor = tester.getRect(find.byKey(triggerKey));
      final popup = tester.getRect(popupText('Copy'));
      expect(popup.center.dy, lessThan(anchor.center.dy));
    });

    testWidgets('flips below when there is no room above', (tester) async {
      await tester.pumpWidget(host(tooltip(), alignment: Alignment.topCenter));

      await tester.longPress(find.byKey(triggerKey));
      await tester.pump(showDelay);
      await tester.pumpAndSettle();

      final anchor = tester.getRect(find.byKey(triggerKey));
      final popup = tester.getRect(popupText('Copy'));
      expect(popup.center.dy, greaterThan(anchor.center.dy));
    });

    testWidgets('stays on screen at textScale 2.0', (tester) async {
      await tester.pumpWidget(
        host(
          tooltip(message: 'A longer hint that wraps across lines'),
          textScale: 2,
          alignment: Alignment.topLeft,
        ),
      );

      await tester.longPress(find.byKey(triggerKey));
      await tester.pump(showDelay);
      await tester.pumpAndSettle();

      final popup = tester.getRect(
        popupText('A longer hint that wraps across lines'),
      );
      expect(popup.left, greaterThanOrEqualTo(0));
      expect(popup.top, greaterThanOrEqualTo(0));
      expect(popup.right, lessThanOrEqualTo(800));
      expect(popup.bottom, lessThanOrEqualTo(600));
    });
  });

  group('motion', () {
    testWidgets('appears at full opacity instantly under reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(host(tooltip(), reduceMotion: true));

      await tester.longPress(find.byKey(triggerKey));
      await tester.pump(showDelay);
      await tester.pump();

      final fade = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fade.opacity.value, 1);

      final scale = tester.widget<ScaleTransition>(
        find.byType(ScaleTransition),
      );
      expect(scale.scale.value, 1, reason: 'no grow-in under reduced motion');
    });
  });

  group('accessibility', () {
    testWidgets('trigger carries tooltip semantics even while hidden', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(tooltip(message: 'Copy link')));

      expect(
        tester.getSemantics(find.byType(FossTooltip)),
        isSemantics(tooltip: 'Copy link'),
      );
      handle.dispose();
    });

    testWidgets('semanticsLabel overrides the announced text', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          FossTooltip(
            message: 'Copy',
            semanticsLabel: 'Copy to clipboard',
            child: triggerBox(key: triggerKey),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(FossTooltip)),
        isSemantics(tooltip: 'Copy to clipboard'),
      );
      handle.dispose();
    });
  });

  group('rtl', () {
    testWidgets('left side resolves to the right edge under RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(tooltip(side: FossTooltipSide.left), direction: TextDirection.rtl),
      );

      await tester.longPress(find.byKey(triggerKey));
      await tester.pump(showDelay);
      await tester.pumpAndSettle();

      final anchor = tester.getRect(find.byKey(triggerKey));
      final popup = tester.getRect(popupText('Copy'));
      expect(popup.center.dx, greaterThan(anchor.center.dx));
    });

    testWidgets('top side stays put under RTL', (tester) async {
      await tester.pumpWidget(
        host(tooltip(), direction: TextDirection.rtl),
      );

      await tester.longPress(find.byKey(triggerKey));
      await tester.pump(showDelay);
      await tester.pumpAndSettle();

      final anchor = tester.getRect(find.byKey(triggerKey));
      final popup = tester.getRect(popupText('Copy'));
      expect(popup.center.dy, lessThan(anchor.center.dy));
    });
  });

  group('surface', () {
    Future<void> showTip(WidgetTester tester) async {
      await tester.longPress(find.byKey(triggerKey));
      await tester.pump(showDelay);
      await tester.pumpAndSettle();
    }

    testWidgets('default surface fills popover with the border role and '
        'radii.md', (tester) async {
      const theme = FossThemeData.light;
      await tester.pumpWidget(host(tooltip()));
      await showTip(tester);

      final surface = popupSurface(tester);
      expect(surface.color, theme.colors.popover);
      final shape = surface.shape;
      expect(shape, isA<RoundedSuperellipseBorder>());
      if (shape case final RoundedSuperellipseBorder s) {
        expect(s.side.color, theme.colors.border);
        expect(s.borderRadius, BorderRadius.circular(theme.radii.md));
      }
    });

    testWidgets('the md shadow ships softened to a 5% tint', (tester) async {
      await tester.pumpWidget(host(tooltip()));
      await showTip(tester);

      final shadows = popupSurface(tester).shadows ?? const [];
      expect(shadows, isNotEmpty);
      for (final shadow in shadows) {
        expect(shadow.color.a, closeTo(0.05, 0.001));
      }
    });

    testWidgets('style overrides reach the popup through build', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          tooltip(
            child: FossTooltip(
              message: 'Copy',
              style: const FossTooltipStyle(
                backgroundColor: Color(0xFF0A0A0A),
                borderColor: Color(0xFF00FF00),
                borderRadius: 20,
                shadows: [BoxShadow(color: Color(0x22000000), blurRadius: 9)],
              ),
              child: triggerBox(key: triggerKey),
            ),
          ),
        ),
      );
      await showTip(tester);

      final surface = popupSurface(tester);
      expect(surface.color, const Color(0xFF0A0A0A));
      expect(surface.shadows, const [
        BoxShadow(color: Color(0x22000000), blurRadius: 9),
      ]);
      final shape = surface.shape;
      if (shape case final RoundedSuperellipseBorder s) {
        expect(s.side.color, const Color(0xFF00FF00));
        expect(s.borderRadius, BorderRadius.circular(20));
      }
    });

    testWidgets('inner ring draws a top edge in light mode', (tester) async {
      await tester.pumpWidget(host(tooltip()));
      await showTip(tester);

      final border = ringBorder(tester);
      expect(border.top, isNot(BorderSide.none));
      expect(border.bottom, BorderSide.none);
    });

    testWidgets('inner ring flips to a bottom edge in dark mode', (
      tester,
    ) async {
      await tester.pumpWidget(host(tooltip(), theme: FossThemeData.dark));
      await showTip(tester);

      final border = ringBorder(tester);
      expect(border.bottom, isNot(BorderSide.none));
      expect(border.top, BorderSide.none);
    });
  });

  group('accessibility (shown)', () {
    testWidgets('the shown popup text stays out of the semantics tree', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(tooltip(message: 'Copy link')));

      await tester.longPress(find.byKey(triggerKey));
      await tester.pump(showDelay);
      await tester.pumpAndSettle();

      expect(popupText('Copy link'), findsOneWidget);
      expect(find.bySemanticsLabel('Copy link'), findsNothing);
      handle.dispose();
    });

    testWidgets('the popup never intercepts pointer input', (tester) async {
      await tester.pumpWidget(host(tooltip()));

      await tester.longPress(find.byKey(triggerKey));
      await tester.pump(showDelay);
      await tester.pumpAndSettle();

      expect(
        find.ancestor(
          of: popupText('Copy'),
          matching: find.byType(IgnorePointer),
        ),
        findsOneWidget,
      );
    });
  });

  group('extra coverage', () {
    testWidgets('re-requesting show while open restarts the animation', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(
          tooltip(
            child: Focus(
              focusNode: node,
              child: triggerBox(key: triggerKey),
            ),
          ),
        ),
      );

      await hover(tester, find.byKey(triggerKey));
      await tester.pump(showDelay);
      await tester.pumpAndSettle();
      expect(popupText('Copy'), findsOneWidget);

      // Focus while already showing re-enters the show path.
      node.requestFocus();
      await tester.pump();
      expect(popupText('Copy'), findsOneWidget);
    });

    testWidgets('opens on the left when there is room', (tester) async {
      await tester.pumpWidget(
        host(
          tooltip(side: FossTooltipSide.left),
          alignment: Alignment.centerRight,
        ),
      );

      await tester.longPress(find.byKey(triggerKey));
      await tester.pump(showDelay);
      await tester.pumpAndSettle();

      final anchor = tester.getRect(find.byKey(triggerKey));
      final popup = tester.getRect(popupText('Copy'));
      expect(popup.center.dx, lessThan(anchor.center.dx));
    });

    testWidgets('opens on the right when there is room', (tester) async {
      await tester.pumpWidget(
        host(
          tooltip(side: FossTooltipSide.right),
          alignment: Alignment.centerLeft,
        ),
      );

      await tester.longPress(find.byKey(triggerKey));
      await tester.pump(showDelay);
      await tester.pumpAndSettle();

      final anchor = tester.getRect(find.byKey(triggerKey));
      final popup = tester.getRect(popupText('Copy'));
      expect(popup.center.dx, greaterThan(anchor.center.dx));
    });

    testWidgets('flips above when there is no room below', (tester) async {
      await tester.pumpWidget(
        host(
          tooltip(side: FossTooltipSide.bottom),
          alignment: Alignment.bottomCenter,
        ),
      );

      await tester.longPress(find.byKey(triggerKey));
      await tester.pump(showDelay);
      await tester.pumpAndSettle();

      final anchor = tester.getRect(find.byKey(triggerKey));
      final popup = tester.getRect(popupText('Copy'));
      expect(popup.center.dy, lessThan(anchor.center.dy));
    });

    testWidgets('rebuilding the host while open relays out the popup', (
      tester,
    ) async {
      late StateSetter setOuter;
      var side = FossTooltipSide.top;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return tooltip(side: side);
            },
          ),
        ),
      );

      await tester.longPress(find.byKey(triggerKey));
      await tester.pump(showDelay);
      await tester.pumpAndSettle();
      expect(popupText('Copy'), findsOneWidget);

      setOuter(() => side = FossTooltipSide.bottom);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
