import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

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
  });
}
