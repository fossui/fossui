import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

void main() {
  Widget host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
      FossTheme(
        data: FossThemeData.light,
        child: Directionality(
          textDirection: direction,
          child: WidgetsApp(
            color: const Color(0xFF000000),
            pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, _, _) => builder(context),
            ),
            home: child,
          ),
        ),
      );

  Future<BuildContext> pumpHost(
    WidgetTester tester, {
    TextDirection direction = TextDirection.ltr,
  }) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
        direction: direction,
      ),
    );
    return ctx;
  }

  // The Padding immediately wrapping the slot whose child is [text].
  EdgeInsets slotPadding(WidgetTester tester, String text) =>
      tester
              .widget<Padding>(
                find
                    .ancestor(
                      of: find.text(text),
                      matching: find.byType(Padding),
                    )
                    .first,
              )
              .padding
          as EdgeInsets;

  // The panel's surface decoration: the drawer's one ShapeDecoration.
  ShapeDecoration panelDecoration(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(FossDrawer),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<ShapeDecoration>()
      .first;

  // The filled footer bar: the drawer's one bordered BoxDecoration.
  BoxDecoration footerDecoration(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(FossDrawer),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((d) => d.border != null);

  group('FossDrawerStyle.merge', () {
    test('other wins per field, null inherits', () {
      const base = FossDrawerStyle(
        backgroundColor: Color(0xFF111111),
        borderRadius: 8,
      );
      final merged = base.merge(
        const FossDrawerStyle(borderRadius: 20, borderColor: Color(0xFF222222)),
      );
      expect(merged.backgroundColor, const Color(0xFF111111));
      expect(merged.borderRadius, 20);
      expect(merged.borderColor, const Color(0xFF222222));
    });

    test('merge null returns this', () {
      const base = FossDrawerStyle(borderRadius: 12);
      expect(identical(base.merge(null), base), isTrue);
    });
  });

  testWidgets('opens, shows the title, and returns the popped value', (
    tester,
  ) async {
    final ctx = await pumpHost(tester);

    final pending = showFossDrawer<bool>(
      context: ctx,
      builder: (context) => FossDrawer(
        title: const Text('Filters'),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Filters'), findsOneWidget);

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('Filters'), findsNothing);
    expect(await pending, isTrue);
  });

  for (final side in FossDrawerSide.values) {
    testWidgets('opens from the $side edge', (tester) async {
      final ctx = await pumpHost(tester);
      unawaited(
        showFossDrawer<void>(
          context: ctx,
          side: side,
          builder: (context) => const FossDrawer(title: Text('Panel')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Panel'), findsOneWidget);
    });
  }

  testWidgets('scrim tap dismisses when barrierDismissible', (tester) async {
    final ctx = await pumpHost(tester);
    unawaited(
      showFossDrawer<void>(
        context: ctx,
        builder: (context) => const FossDrawer(title: Text('Hi')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hi'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Hi'), findsNothing);
  });

  testWidgets('scrim tap is blocked when barrierDismissible is false', (
    tester,
  ) async {
    final ctx = await pumpHost(tester);
    unawaited(
      showFossDrawer<void>(
        context: ctx,
        barrierDismissible: false,
        builder: (context) => const FossDrawer(title: Text('Stuck')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Stuck'), findsOneWidget);
  });

  testWidgets('close button shows on flag, dismisses, and is labelled', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final ctx = await pumpHost(tester);
    unawaited(
      showFossDrawer<void>(
        context: ctx,
        builder: (context) =>
            const FossDrawer(title: Text('Sheet'), showCloseButton: true),
      ),
    );
    await tester.pumpAndSettle();

    final closeFinder = find.bySemanticsLabel('Close');
    expect(closeFinder, findsOneWidget);
    expect(
      tester.getSemantics(closeFinder),
      matchesSemantics(label: 'Close', isButton: true, hasTapAction: true),
    );

    await tester.tap(closeFinder);
    await tester.pumpAndSettle();
    expect(find.text('Sheet'), findsNothing);
    handle.dispose();
  });

  testWidgets('renders with a drag handle', (tester) async {
    final ctx = await pumpHost(tester);
    unawaited(
      showFossDrawer<void>(
        context: ctx,
        builder: (context) =>
            const FossDrawer(title: Text('Grab'), showHandle: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Grab'), findsOneWidget);
    expect(find.byType(FossDrawer), findsOneWidget);
  });

  testWidgets('header-absent renders content only', (tester) async {
    final ctx = await pumpHost(tester);
    unawaited(
      showFossDrawer<void>(
        context: ctx,
        builder: (context) => const FossDrawer(content: Text('Body only')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Body only'), findsOneWidget);
  });

  testWidgets('drag past the threshold dismisses', (tester) async {
    final ctx = await pumpHost(tester);
    unawaited(
      showFossDrawer<void>(
        context: ctx,
        builder: (context) => const FossDrawer(title: Text('Dragme')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dragme'), findsOneWidget);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Dragme')),
    );
    await gesture.moveBy(const Offset(0, 500));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Dragme'), findsNothing);
  });

  testWidgets('a short drag springs back', (tester) async {
    final ctx = await pumpHost(tester);
    unawaited(
      showFossDrawer<void>(
        context: ctx,
        builder: (context) => const FossDrawer(title: Text('Springy')),
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Springy')),
    );
    await gesture.moveBy(const Offset(0, 8));
    // Pause so the release carries no fling velocity.
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Springy'), findsOneWidget);
  });

  testWidgets('left drawer anchors to the start edge', (tester) async {
    final ctx = await pumpHost(tester);
    unawaited(
      showFossDrawer<void>(
        context: ctx,
        side: FossDrawerSide.left,
        builder: (context) => const FossDrawer(title: Text('Side')),
      ),
    );
    await tester.pumpAndSettle();
    final left = tester.getTopLeft(find.text('Side')).dx;
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(left, lessThan(width / 2));
  });

  testWidgets('reduced motion still opens and closes', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: host(
          Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    unawaited(
      showFossDrawer<void>(
        context: ctx,
        builder: (context) => const FossDrawer(title: Text('Instant')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Instant'), findsOneWidget);
  });

  testWidgets('renders a description in the header', (tester) async {
    final ctx = await pumpHost(tester);
    unawaited(
      showFossDrawer<void>(
        context: ctx,
        builder: (context) => const FossDrawer(
          title: Text('Titled'),
          description: Text('A supporting line.'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A supporting line.'), findsOneWidget);
  });

  testWidgets('drag off the top edge dismisses', (tester) async {
    final ctx = await pumpHost(tester);
    unawaited(
      showFossDrawer<void>(
        context: ctx,
        side: FossDrawerSide.top,
        builder: (context) => const FossDrawer(title: Text('Topper')),
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Topper')),
    );
    await gesture.moveBy(const Offset(0, -500));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Topper'), findsNothing);
  });

  for (final (side, delta) in <(FossDrawerSide, Offset)>[
    (FossDrawerSide.left, Offset(-500, 0)),
    (FossDrawerSide.right, Offset(500, 0)),
  ]) {
    testWidgets('drag off the $side edge dismisses', (tester) async {
      final ctx = await pumpHost(tester);
      unawaited(
        showFossDrawer<void>(
          context: ctx,
          side: side,
          builder: (context) => const FossDrawer(title: Text('Panel')),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Panel')),
      );
      await gesture.moveBy(delta);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Panel'), findsNothing);
    });
  }

  testWidgets('a side panel shows its handle on the exposed edge', (
    tester,
  ) async {
    final ctx = await pumpHost(tester);
    unawaited(
      showFossDrawer<void>(
        context: ctx,
        side: FossDrawerSide.right,
        builder: (context) =>
            const FossDrawer(title: Text('Rail'), showHandle: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rail'), findsOneWidget);
  });

  testWidgets('bottom drawer without actions pads the safe area', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(bottom: 40);
    addTearDown(tester.view.resetPadding);

    final ctx = await pumpHost(tester);
    unawaited(
      showFossDrawer<void>(
        context: ctx,
        builder: (context) => const FossDrawer(content: Text('No footer')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No footer'), findsOneWidget);
  });

  testWidgets('survives an external rebuild while open', (tester) async {
    final ctx = await pumpHost(tester);
    unawaited(
      showFossDrawer<void>(
        context: ctx,
        builder: (context) => const FossDrawer(title: Text('Persist')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Persist'), findsOneWidget);

    // Re-pump the whole tree: the route's page rebuilds, updating the side
    // scope in place.
    await pumpHost(tester);
    await tester.pumpAndSettle();
    expect(find.text('Persist'), findsOneWidget);
  });

  testWidgets('renders on a dark theme', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      FossTheme(
        data: FossThemeData.dark,
        child: WidgetsApp(
          color: const Color(0xFF000000),
          pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    unawaited(
      showFossDrawer<void>(
        context: ctx,
        builder: (context) => const FossDrawer(
          title: Text('Dark'),
          footerVariant: FossDrawerFooterVariant.filled,
          actions: [Text('OK')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dark'), findsOneWidget);
  });

  group('seam padding', () {
    testWidgets('adjacent slots collapse their touching insets', (
      tester,
    ) async {
      final ctx = await pumpHost(tester);
      unawaited(
        showFossDrawer<void>(
          context: ctx,
          builder: (context) => const FossDrawer(
            title: Text('Head'),
            content: Text('Body'),
            actions: [Text('OK')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header keeps its top and sides at 24, tightens its bottom to 16.
      expect(
        slotPadding(tester, 'Head'),
        const EdgeInsets.fromLTRB(24, 24, 24, 16),
      );
      // Content drops both touching edges to 0.
      expect(
        slotPadding(tester, 'Body'),
        const EdgeInsets.fromLTRB(24, 0, 24, 0),
      );
    });

    testWidgets('a lone content slot keeps the full inset', (tester) async {
      final ctx = await pumpHost(tester);
      unawaited(
        showFossDrawer<void>(
          context: ctx,
          builder: (context) => const FossDrawer(content: Text('Only')),
        ),
      );
      await tester.pumpAndSettle();

      expect(slotPadding(tester, 'Only'), const EdgeInsets.all(24));
    });
  });

  group('drag', () {
    testWidgets('a fast fling dismisses before the halfway threshold', (
      tester,
    ) async {
      final ctx = await pumpHost(tester);
      unawaited(
        showFossDrawer<void>(
          context: ctx,
          builder: (context) => const FossDrawer(
            title: Text('Flung'),
            content: SizedBox(height: 400),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A short, fast outward fling: well under half the panel, high velocity.
      await tester.fling(
        find.text('Flung'),
        const Offset(0, 60),
        2000,
      );
      await tester.pumpAndSettle();
      expect(find.text('Flung'), findsNothing);
    });

    testWidgets('a drag dismiss resolves the future with null', (tester) async {
      final ctx = await pumpHost(tester);
      final pending = showFossDrawer<String>(
        context: ctx,
        builder: (context) => const FossDrawer(title: Text('Dragaway')),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Dragaway')),
      );
      await gesture.moveBy(const Offset(0, 500));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(await pending, isNull);
    });

    testWidgets('a below-threshold drag springs back under reduced motion', (
      tester,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: host(
            Builder(
              builder: (context) {
                ctx = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      unawaited(
        showFossDrawer<void>(
          context: ctx,
          builder: (context) => const FossDrawer(title: Text('Snap')),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Snap')),
      );
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 400));
      await gesture.up();
      // The zero-duration settle snaps back in a single frame.
      await tester.pump();
      expect(find.text('Snap'), findsOneWidget);
    });
  });

  group('surface and variants', () {
    testWidgets('style overrides reach the panel surface', (tester) async {
      final ctx = await pumpHost(tester);
      unawaited(
        showFossDrawer<void>(
          context: ctx,
          builder: (context) => const FossDrawer(
            title: Text('Styled'),
            style: FossDrawerStyle(
              backgroundColor: Color(0xFF101014),
              borderColor: Color(0xFF00FF00),
              shadows: [BoxShadow(color: Color(0x22000000), blurRadius: 5)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dec = panelDecoration(tester);
      expect(dec.color, const Color(0xFF101014));
      expect(dec.shadows, const [
        BoxShadow(color: Color(0x22000000), blurRadius: 5),
      ]);
      expect(
        (dec.shape as RoundedSuperellipseBorder).side.color,
        const Color(0xFF00FF00),
      );
    });

    testWidgets('the straight variant squares every corner', (tester) async {
      final ctx = await pumpHost(tester);
      unawaited(
        showFossDrawer<void>(
          context: ctx,
          builder: (context) => const FossDrawer(
            title: Text('Square'),
            variant: FossDrawerVariant.straight,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final shape = panelDecoration(tester).shape as RoundedSuperellipseBorder;
      expect(shape.borderRadius, BorderRadius.zero);
    });

    testWidgets('the filled footer tints a bordered bar', (tester) async {
      final ctx = await pumpHost(tester);
      unawaited(
        showFossDrawer<void>(
          context: ctx,
          builder: (context) => const FossDrawer(
            title: Text('Filled'),
            footerVariant: FossDrawerFooterVariant.filled,
            actions: [Text('OK')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dec = footerDecoration(tester);
      final muted = FossThemeData.light.colors.muted;
      expect(dec.color, muted.withValues(alpha: muted.a * 0.72));
      if (dec.border case final Border b) {
        expect(b.top.color, FossThemeData.light.colors.border);
      }
    });

    testWidgets('a custom close icon replaces the default glyph', (
      tester,
    ) async {
      final ctx = await pumpHost(tester);
      unawaited(
        showFossDrawer<void>(
          context: ctx,
          builder: (context) => const FossDrawer(
            title: Text('Iconed'),
            showCloseButton: true,
            closeIcon: Text('xx'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('xx'), findsOneWidget);
    });
  });

  testWidgets('a left drawer mirrors to the end edge under RTL', (
    tester,
  ) async {
    final ctx = await pumpHost(tester);
    unawaited(
      showFossDrawer<void>(
        context: ctx,
        side: FossDrawerSide.left,
        builder: (context) => const Directionality(
          textDirection: TextDirection.rtl,
          child: FossDrawer(title: Text('Rail')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // A start-anchored panel mirrors to the end (right) edge under RTL, so the
    // panel's right edge sits at the viewport edge.
    final panel = tester.getRect(
      find
          .descendant(
            of: find.byType(FossDrawer),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(panel.right, moreOrLessEquals(width, epsilon: 1));
  });

  testWidgets('opens at 2x text scale without overflow', (tester) async {
    final ctx = await pumpHost(tester);
    unawaited(
      showFossDrawer<void>(
        context: ctx,
        builder: (context) => Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
            ),
            child: const FossDrawer(
              title: Text('Scaled'),
              description: Text('A supporting line that grows with the text.'),
              content: Text('Body'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scaled'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('content scroll fade', () {
    testWidgets('does not fade when content fits', (tester) async {
      final ctx = await pumpHost(tester);
      unawaited(
        showFossDrawer<void>(
          context: ctx,
          builder: (context) => const FossDrawer(content: Text('Short body')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('fades the scroll edge when content overflows', (tester) async {
      final ctx = await pumpHost(tester);
      unawaited(
        showFossDrawer<void>(
          context: ctx,
          builder: (context) =>
              const FossDrawer(content: SizedBox(height: 4000)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('keeps fading after scrolling to the end', (tester) async {
      final ctx = await pumpHost(tester);
      unawaited(
        showFossDrawer<void>(
          context: ctx,
          builder: (context) =>
              const FossDrawer(content: SizedBox(height: 4000)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -4000),
      );
      await tester.pumpAndSettle();

      // At the bottom the top edge now fades; the mask stays present.
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('ignores a nested scrollable inside fitting content', (
      tester,
    ) async {
      final ctx = await pumpHost(tester);
      unawaited(
        showFossDrawer<void>(
          context: ctx,
          builder: (context) => FossDrawer(
            // The drawer body itself fits; only an inner list overflows. Its
            // scroll must not drive the drawer edge fade.
            content: SizedBox(
              height: 80,
              child: ListView(children: const [SizedBox(height: 4000)]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShaderMask), findsNothing);
    });
  });
}
