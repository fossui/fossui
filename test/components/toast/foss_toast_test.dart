import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

void main() {
  late BuildContext ctx;

  Widget host({FossThemeData? data}) => FossTheme(
    data: data ?? FossThemeData.light,
    child: WidgetsApp(
      color: const Color(0xFF000000),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: FossToaster(
        child: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );

  testWidgets('shows a toast and auto-dismisses after its duration', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    showFossToast(
      ctx,
      const FossToast(
        type: FossToastType.success,
        title: Text('Saved'),
        duration: Duration(milliseconds: 100),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Saved'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('loading persists and update flips it to a status', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    final id = FossToastScope.of(ctx).show(
      const FossToast(type: FossToastType.loading, title: Text('Uploading')),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Uploading'), findsOneWidget); // no auto-dismiss

    FossToastScope.of(ctx).update(
      id,
      const FossToast(
        type: FossToastType.success,
        title: Text('Uploaded'),
        duration: Duration(milliseconds: 100),
      ),
    );
    await tester.pump();
    expect(find.text('Uploaded'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Uploaded'), findsNothing);
  });

  testWidgets('throws without a FossToaster ancestor', (tester) async {
    await tester.pumpWidget(
      FossTheme(
        data: FossThemeData.light,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(
      () => showFossToast(ctx, const FossToast(title: Text('x'))),
      throwsFlutterError,
    );
  });

  testWidgets('renders the leading glyph and description for each status', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    const types = [
      FossToastType.info,
      FossToastType.warning,
      FossToastType.error,
    ];
    for (final type in types) {
      FossToastScope.of(ctx).show(
        FossToast(
          type: type,
          title: Text(type.name),
          description: const Text('details'),
        ),
      );
    }
    await tester.pump();

    for (final type in types) {
      expect(find.text(type.name), findsOneWidget);
    }
    expect(find.text('details'), findsNWidgets(types.length));
  });

  testWidgets('shows only the most recent toasts past the visible cap', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    for (var i = 0; i < FossToastController.maxVisible + 1; i++) {
      FossToastScope.of(ctx).show(
        FossToast(type: FossToastType.loading, title: Text('toast $i')),
      );
    }
    await tester.pump();

    expect(find.text('toast 0'), findsNothing);
    expect(find.text('toast 3'), findsOneWidget);
  });

  testWidgets('swiping a toast down dismisses it', (tester) async {
    await tester.pumpWidget(host());

    FossToastScope.of(ctx).show(
      const FossToast(
        title: Text('Swipe me'),
        duration: Duration(hours: 1),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Swipe me'), findsOneWidget);

    await tester.fling(find.text('Swipe me'), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Swipe me'), findsNothing);
  });

  testWidgets('swiping a toast sideways dismisses it', (tester) async {
    await tester.pumpWidget(host());

    FossToastScope.of(ctx).show(
      const FossToast(title: Text('Fling me'), duration: Duration(hours: 1)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fling me'), findsOneWidget);

    await tester.fling(find.text('Fling me'), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Fling me'), findsNothing);
  });

  testWidgets('a queued toast does not run its timer while hidden', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    // Oldest first, so this auto-dismiss toast sits behind the newer loaders
    // and stays hidden past the visible cap.
    final hidden = FossToastScope.of(ctx).show(
      const FossToast(
        title: Text('queued'),
        duration: Duration(milliseconds: 100),
      ),
    );
    for (var i = 0; i < FossToastController.maxVisible; i++) {
      FossToastScope.of(ctx).show(
        FossToast(type: FossToastType.loading, title: Text('load $i')),
      );
    }
    await tester.pump();
    expect(find.text('queued'), findsNothing);

    // Well past its duration: a hidden toast's countdown never ran, so it is
    // still queued rather than expired unseen.
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      FossToastScope.of(ctx).entries.any((e) => e.id == hidden),
      isTrue,
    );
  });

  testWidgets('pressing a toast holds it open past its duration', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    final id = FossToastScope.of(ctx).show(
      const FossToast(title: Text('Hold'), duration: Duration(seconds: 5)),
    );
    await tester.pumpAndSettle(); // settle the entrance; the 5s timer stays

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Hold')),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 8)); // past duration, held down
    expect(
      FossToastScope.of(ctx).entries.any((e) => e.id == id),
      isTrue,
      reason: 'a pressed toast does not auto-dismiss',
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('an error stays off the live region, other types stay on it', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    final handle = tester.ensureSemantics();

    FossToastScope.of(ctx).show(
      const FossToast(type: FossToastType.info, title: Text('info-toast')),
    );
    FossToastScope.of(ctx).show(
      const FossToast(type: FossToastType.error, title: Text('error-toast')),
    );
    await tester.pumpAndSettle();

    Semantics surfaceOf(String text) => tester.widget<Semantics>(
      find
          .ancestor(of: find.text(text), matching: find.byType(Semantics))
          .first,
    );
    expect(surfaceOf('info-toast').properties.liveRegion, isTrue);
    expect(surfaceOf('error-toast').properties.liveRegion, isFalse);
    handle.dispose();
  });

  testWidgets('an icon overrides the default leading glyph', (tester) async {
    await tester.pumpWidget(host());

    FossToastScope.of(ctx).show(
      const FossToast(
        type: FossToastType.info,
        icon: SizedBox(key: Key('custom-icon')),
        title: Text('x'),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('custom-icon')), findsOneWidget);
  });

  testWidgets('a zero-duration toast persists', (tester) async {
    await tester.pumpWidget(host());

    FossToastScope.of(ctx).show(
      const FossToast(title: Text('sticky'), duration: Duration.zero),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));

    expect(find.text('sticky'), findsOneWidget);
  });

  testWidgets('a per-instance style reaches the surface decoration', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    FossToastScope.of(ctx).show(
      const FossToast(
        title: Text('styled'),
        style: FossToastStyle(
          backgroundColor: Color(0xFF102030),
          borderColor: Color(0xFF405060),
          borderRadius: 4,
        ),
      ),
    );
    await tester.pump();

    final decoration =
        tester
                .widget<DecoratedBox>(
                  find
                      .ancestor(
                        of: find.text('styled'),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as ShapeDecoration;
    expect(decoration.color, const Color(0xFF102030));
    final shape = decoration.shape as RoundedSuperellipseBorder;
    expect(shape.side.color, const Color(0xFF405060));
  });

  testWidgets('renders on the popover surface under a dark theme', (
    tester,
  ) async {
    await tester.pumpWidget(host(data: FossThemeData.dark));

    FossToastScope.of(ctx).show(const FossToast(title: Text('dark-toast')));
    await tester.pump();

    final decoration =
        tester
                .widget<DecoratedBox>(
                  find
                      .ancestor(
                        of: find.text('dark-toast'),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as ShapeDecoration;
    expect(decoration.color, FossThemeData.dark.colors.popover);
  });

  group('FossToastStyle.merge', () {
    test('lays each non-null field of the argument over the receiver', () {
      const base = FossToastStyle(
        backgroundColor: Color(0xFF000000),
        borderColor: Color(0xFF111111),
        borderRadius: 8,
      );
      const over = FossToastStyle(borderRadius: 12);

      final merged = base.merge(over);

      expect(merged.borderRadius, 12, reason: 'overridden');
      expect(merged.backgroundColor, const Color(0xFF000000));
      expect(merged.borderColor, const Color(0xFF111111));
    });

    test('a null argument keeps the receiver unchanged', () {
      const base = FossToastStyle(borderRadius: 8);

      expect(base.merge(null), same(base));
    });

    test('text styles override while unset fields fall back', () {
      const base = FossToastStyle(
        titleStyle: TextStyle(fontSize: 10),
        descriptionStyle: TextStyle(fontSize: 12),
      );
      const over = FossToastStyle(titleStyle: TextStyle(fontSize: 20));

      final merged = base.merge(over);

      expect(merged.titleStyle!.fontSize, 20);
      expect(merged.descriptionStyle!.fontSize, 12);
    });
  });

  group('FossToastController', () {
    test('clear cancels pending timers and empties the queue', () {
      final controller = FossToastController();
      addTearDown(controller.dispose);

      controller
        ..show(const FossToast(title: Text('a')))
        ..show(const FossToast(title: Text('b')));
      expect(controller.entries, hasLength(2));

      controller.clear();
      expect(controller.entries, isEmpty);
    });

    test('dispose cancels the auto-dismiss timers of live toasts', () {
      final controller = FossToastController()
        ..show(const FossToast(title: Text('a')));

      expect(controller.dispose, returnsNormally);
    });

    test(
      'show returns a fresh id; update and dismiss on a missing id no-op',
      () {
        final controller = FossToastController();
        addTearDown(controller.dispose);

        final first = controller.show(const FossToast(title: Text('a')));
        final second = controller.show(const FossToast(title: Text('b')));
        expect(second, greaterThan(first));

        controller
          ..update(999, const FossToast(title: Text('x')))
          ..dismiss(999);
        expect(controller.entries, hasLength(2));

        controller.dismiss(first);
        expect(controller.entries, hasLength(1));
      },
    );
  });
}
