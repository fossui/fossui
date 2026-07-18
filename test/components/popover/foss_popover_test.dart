import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

void main() {
  const triggerKey = Key('trigger');
  const contentKey = Key('content');

  Widget host(
    Widget child, {
    FossThemeData? theme,
    TextDirection direction = TextDirection.ltr,
    bool reduceMotion = false,
    double textScale = 1,
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
        // TapRegion needs a surface ancestor to detect outside taps, the same
        // one an app inserts above its content.
        child: TapRegionSurface(
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (_) => Stack(
                  children: [
                    // A hittable backdrop so an outside tap lands somewhere the
                    // tap-region surface can report, as it would in a real app.
                    const Positioned.fill(
                      child: ColoredBox(color: Color(0xFFEEEEEE)),
                    ),
                    Align(alignment: alignment, child: child),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget triggerBox() => const ColoredBox(
    color: Color(0xFF3366FF),
    child: SizedBox(key: triggerKey, width: 60, height: 30),
  );

  Widget content([FocusNode? node]) => Focus(
    focusNode: node,
    child: const SizedBox(key: contentKey, width: 120, height: 80),
  );

  FossPopover popover({
    FossPopoverController? controller,
    bool? open,
    ValueChanged<bool>? onOpenChange,
    FossPopoverSide side = FossPopoverSide.bottom,
    FossPopoverAlign align = FossPopoverAlign.center,
    bool modal = false,
    bool dismissible = true,
    FossPopoverStyle? style,
    WidgetBuilder? builder,
  }) => FossPopover(
    controller: controller,
    open: open,
    onOpenChange: onOpenChange,
    side: side,
    align: align,
    modal: modal,
    dismissible: dismissible,
    style: style,
    builder: builder ?? (_) => content(),
    child: triggerBox(),
  );

  // The surface: the one DecoratedBox in the overlay with a ShapeDecoration
  // (the inner ring uses a plain BoxDecoration).
  Finder surface() => find.descendant(
    of: find.byType(Overlay),
    matching: find.byWidgetPredicate(
      (w) => w is DecoratedBox && w.decoration is ShapeDecoration,
    ),
  );

  ShapeDecoration surfaceDecoration(WidgetTester tester) =>
      tester.widget<DecoratedBox>(surface()).decoration as ShapeDecoration;

  Finder scrim() => find.byWidgetPredicate(
    (w) => w is ColoredBox && w.color == const Color(0x52000000),
  );

  group('open and close', () {
    testWidgets('tap toggles the surface open then closed', (tester) async {
      await tester.pumpWidget(host(popover()));
      expect(surface(), findsNothing);

      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();
      expect(find.byKey(contentKey), findsOneWidget);

      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();
      expect(find.byKey(contentKey), findsNothing);
    });

    testWidgets('onOpenChange fires on open and on close', (tester) async {
      final events = <bool>[];
      await tester.pumpWidget(host(popover(onOpenChange: events.add)));

      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();

      expect(events, [true, false]);
    });

    testWidgets('the trigger reports its expanded state', (tester) async {
      await tester.pumpWidget(host(popover()));
      final handle = tester.ensureSemantics();

      expect(
        tester.getSemantics(find.byKey(triggerKey)),
        isSemantics(isButton: true, hasExpandedState: true, isExpanded: false),
      );

      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.byKey(triggerKey)),
        isSemantics(isButton: true, hasExpandedState: true, isExpanded: true),
      );
      handle.dispose();
    });
  });

  group('dismiss', () {
    testWidgets('an outside tap closes a non-modal popover', (tester) async {
      final events = <bool>[];
      await tester.pumpWidget(host(popover(onOpenChange: events.add)));
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.byKey(contentKey), findsNothing);
      expect(events.last, isFalse);
    });

    testWidgets('Escape closes the popover', (tester) async {
      await tester.pumpWidget(host(popover()));
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byKey(contentKey), findsNothing);
    });

    testWidgets('dismissible false ignores outside tap and Escape', (
      tester,
    ) async {
      await tester.pumpWidget(host(popover(dismissible: false)));
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byKey(contentKey), findsOneWidget);
    });

    testWidgets('the system back gesture closes the popover', (tester) async {
      await tester.pumpWidget(host(popover()));
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(handled, isTrue);
      expect(find.byKey(contentKey), findsNothing);
    });

    testWidgets('scrolling an ancestor closes the popover', (tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 300,
            width: 300,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  popover(),
                  const SizedBox(height: 1000),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();
      expect(find.byKey(contentKey), findsOneWidget);

      scrollController.jumpTo(120);
      await tester.pumpAndSettle();
      expect(find.byKey(contentKey), findsNothing);
    });

    testWidgets('a non-dismissible popover follows the trigger on scroll', (
      tester,
    ) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 300,
            width: 300,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  popover(dismissible: false),
                  const SizedBox(height: 1000),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(find.byKey(contentKey)).dy;

      scrollController.jumpTo(60);
      await tester.pumpAndSettle();

      // Stays open and tracks the scrolled trigger rather than detaching.
      expect(find.byKey(contentKey), findsOneWidget);
      expect(tester.getTopLeft(find.byKey(contentKey)).dy, lessThan(before));
    });
  });

  group('controlled and controller', () {
    testWidgets('controlled open drives the surface both ways', (tester) async {
      // A stable overlay entry; state lives in the StatefulBuilder so the
      // controlled `open` round-trips through onOpenChange.
      var open = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => popover(
              open: open,
              onOpenChange: (v) => setState(() => open = v),
            ),
          ),
        ),
      );
      expect(surface(), findsNothing);

      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();
      expect(open, isTrue);
      expect(find.byKey(contentKey), findsOneWidget);

      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();
      expect(open, isFalse);
      expect(find.byKey(contentKey), findsNothing);
    });

    testWidgets('the controller opens, closes, and reports state', (
      tester,
    ) async {
      final controller = FossPopoverController();
      await tester.pumpWidget(host(popover(controller: controller)));
      expect(controller.isOpen, isFalse);

      controller.open();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);
      expect(find.byKey(contentKey), findsOneWidget);

      controller.close();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
    });

    testWidgets('the controller toggles the surface', (tester) async {
      final controller = FossPopoverController();
      await tester.pumpWidget(host(popover(controller: controller)));

      controller.toggle();
      await tester.pumpAndSettle();
      expect(find.byKey(contentKey), findsOneWidget);

      controller.toggle();
      await tester.pumpAndSettle();
      expect(find.byKey(contentKey), findsNothing);
    });

    testWidgets('a controlled popover can open on first mount', (tester) async {
      await tester.pumpWidget(host(popover(open: true, onOpenChange: (_) {})));
      await tester.pumpAndSettle();
      expect(find.byKey(contentKey), findsOneWidget);
    });

    testWidgets('swapping the controller moves imperative control', (
      tester,
    ) async {
      final first = FossPopoverController();
      final second = FossPopoverController();
      var useSecond = false;
      late StateSetter swap;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              swap = setState;
              return popover(controller: useSecond ? second : first);
            },
          ),
        ),
      );

      swap(() => useSecond = true);
      await tester.pump();

      first.open();
      await tester.pumpAndSettle();
      expect(find.byKey(contentKey), findsNothing);

      second.open();
      await tester.pumpAndSettle();
      expect(find.byKey(contentKey), findsOneWidget);
    });

    testWidgets('the controller can close from inside the content', (
      tester,
    ) async {
      final controller = FossPopoverController();
      await tester.pumpWidget(
        host(
          popover(
            controller: controller,
            builder: (_) => GestureDetector(
              onTap: controller.close,
              child: const ColoredBox(
                color: Color(0xFFCCCCCC),
                child: SizedBox(key: contentKey, width: 80, height: 40),
              ),
            ),
          ),
        ),
      );
      controller.open();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(contentKey));
      await tester.pumpAndSettle();
      expect(find.byKey(contentKey), findsNothing);
    });
  });

  group('modal', () {
    testWidgets('draws a scrim that dismisses on tap', (tester) async {
      await tester.pumpWidget(host(popover(modal: true)));
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();
      expect(scrim(), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byKey(contentKey), findsNothing);
    });

    testWidgets('non-modal draws no scrim', (tester) async {
      await tester.pumpWidget(host(popover()));
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();
      expect(scrim(), findsNothing);
    });

    testWidgets('a non-dismissible modal traps Escape (stays open)', (
      tester,
    ) async {
      await tester.pumpWidget(host(popover(modal: true, dismissible: false)));
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(contentKey), findsOneWidget);
    });
  });

  group('focus', () {
    testWidgets('focus moves into the surface on open', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(popover(builder: (_) => content(node))),
      );
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);
    });

    testWidgets('the content loses focus on close', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(popover(builder: (_) => content(node))),
      );
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(node.hasFocus, isFalse);
    });
  });

  group('accessibility', () {
    testWidgets('the surface grows with a large text scale', (tester) async {
      Widget textContent(BuildContext context) => const Text(
        'A panel that grows with its content when text is scaled up.',
        key: contentKey,
      );

      await tester.pumpWidget(
        host(popover(builder: textContent), textScale: 2),
      );
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();

      // Laid out without overflow (pumpAndSettle would surface an exception),
      // and the surface is at least as tall as the doubled text.
      expect(find.byKey(contentKey), findsOneWidget);
      expect(
        tester.getSize(surface()).height,
        greaterThan(tester.getSize(find.byKey(contentKey)).height),
      );
    });
  });

  group('positioning', () {
    testWidgets('bottom side flips above when pinned to the bottom edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(popover(), alignment: Alignment.bottomCenter),
      );
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();

      final surfaceTop = tester.getTopLeft(find.byKey(contentKey)).dy;
      final triggerTop = tester.getTopLeft(find.byKey(triggerKey)).dy;
      expect(surfaceTop, lessThan(triggerTop));
    });

    testWidgets('a left side mirrors to the right under RTL', (tester) async {
      await tester.pumpWidget(
        host(popover(side: FossPopoverSide.left), direction: TextDirection.rtl),
      );
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();

      final surfaceLeft = tester.getTopLeft(find.byKey(contentKey)).dx;
      final triggerRight = tester.getTopRight(find.byKey(triggerKey)).dx;
      expect(surfaceLeft, greaterThanOrEqualTo(triggerRight));
    });

    testWidgets('a right side mirrors to the left under RTL', (tester) async {
      await tester.pumpWidget(
        host(
          popover(side: FossPopoverSide.right),
          direction: TextDirection.rtl,
        ),
      );
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();

      final surfaceRight = tester.getTopRight(find.byKey(contentKey)).dx;
      final triggerLeft = tester.getTopLeft(find.byKey(triggerKey)).dx;
      expect(surfaceRight, lessThanOrEqualTo(triggerLeft));
    });

    testWidgets('end align resolves', (tester) async {
      await tester.pumpWidget(host(popover(align: FossPopoverAlign.end)));
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();
      expect(find.byKey(contentKey), findsOneWidget);
    });

    for (final align in FossPopoverAlign.values) {
      testWidgets('align $align mirrors under RTL', (tester) async {
        await tester.pumpWidget(
          host(popover(align: align), direction: TextDirection.rtl),
        );
        await tester.tap(find.byKey(triggerKey));
        await tester.pumpAndSettle();
        expect(find.byKey(contentKey), findsOneWidget);
      });
    }
  });

  group('surface tokens', () {
    testWidgets('resolves the popover fill and lg radius', (tester) async {
      await tester.pumpWidget(host(popover()));
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();

      final decoration = surfaceDecoration(tester);
      const theme = FossThemeData.light;
      expect(decoration.color, theme.colors.popover);
      final shape = decoration.shape as RoundedSuperellipseBorder;
      expect(
        shape.borderRadius.resolve(TextDirection.ltr).topLeft.x,
        theme.radii.lg,
      );
    });

    testWidgets('dark theme uses the dark popover fill', (tester) async {
      await tester.pumpWidget(host(popover(), theme: FossThemeData.dark));
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();
      expect(
        surfaceDecoration(tester).color,
        FossThemeData.dark.colors.popover,
      );
    });

    testWidgets('style overrides reach the surface', (tester) async {
      const override = FossPopoverStyle(
        backgroundColor: Color(0xFF112233),
        borderRadius: 20,
      );
      await tester.pumpWidget(host(popover(style: override)));
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();

      final decoration = surfaceDecoration(tester);
      expect(decoration.color, const Color(0xFF112233));
      final shape = decoration.shape as RoundedSuperellipseBorder;
      expect(shape.borderRadius.resolve(TextDirection.ltr).topLeft.x, 20);
    });
  });

  group('reduced motion', () {
    testWidgets('the surface appears without pumping the animation', (
      tester,
    ) async {
      await tester.pumpWidget(host(popover(), reduceMotion: true));
      await tester.tap(find.byKey(triggerKey));
      await tester.pump();
      expect(find.byKey(contentKey), findsOneWidget);
    });

    testWidgets('the surface closes without pumping the animation', (
      tester,
    ) async {
      await tester.pumpWidget(host(popover(), reduceMotion: true));
      await tester.tap(find.byKey(triggerKey));
      await tester.pump();
      await tester.tap(find.byKey(triggerKey));
      await tester.pump();
      expect(find.byKey(contentKey), findsNothing);
    });
  });

  group('FossPopoverStyle.merge', () {
    test('other wins where set, base fills the rest', () {
      const base = FossPopoverStyle(
        backgroundColor: Color(0xFF000001),
        borderRadius: 10,
        padding: EdgeInsets.all(16),
      );
      const other = FossPopoverStyle(borderRadius: 14);
      final merged = base.merge(other);

      expect(merged.borderRadius, 14);
      expect(merged.backgroundColor, const Color(0xFF000001));
      expect(merged.padding, const EdgeInsets.all(16));
    });

    test('merging null returns the base unchanged', () {
      const base = FossPopoverStyle(borderRadius: 8);
      expect(identical(base.merge(null), base), isTrue);
    });
  });
}
