import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

void main() {
  Widget host(Widget child) => FossTheme(
    data: FossThemeData.light,
    child: WidgetsApp(
      color: const Color(0xFF000000),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: child,
    ),
  );

  testWidgets('opens, shows the title, and returns the popped value', (
    tester,
  ) async {
    late BuildContext ctx;

    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );

    final pending = showFossDialog<bool>(
      context: ctx,
      builder: (context) => FossDialog(
        title: const Text('Delete project'),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete project'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Delete project'), findsNothing);
    expect(await pending, isTrue);
  });

  testWidgets('scrim tap dismisses when barrierDismissible', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );

    unawaited(
      showFossDialog<void>(
        context: ctx,
        builder: (context) => const FossDialog(title: Text('Hi')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hi'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Hi'), findsNothing);
  });

  testWidgets('renders body, description, bare footer, and closes', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    late BuildContext ctx;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );

    unawaited(
      showFossDialog<void>(
        context: ctx,
        builder: (context) => FossDialog(
          title: const Text('Details'),
          description: const Text('The full story.'),
          content: const Text('Body copy.'),
          footerVariant: FossDialogFooterVariant.bare,
          style: const FossDialogStyle(maxWidth: 400),
          actions: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Details'), findsOneWidget);
    expect(find.text('The full story.'), findsOneWidget);
    expect(find.text('Body copy.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsNothing);
    handle.dispose();
  });

  testWidgets('names the modal route for assistive technology', (tester) async {
    final handle = tester.ensureSemantics();
    late BuildContext ctx;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );

    unawaited(
      showFossDialog<void>(
        context: ctx,
        builder: (context) => const FossDialog(
          title: Text('Delete project'),
          semanticLabel: 'Delete project dialog',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Delete project dialog'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('caps the card at the default and the overridden width', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );

    Future<double> cardWidth() async {
      await tester.pumpAndSettle();
      return tester
          .getSize(
            find
                .descendant(
                  of: find.byType(FossDialog),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .width;
    }

    unawaited(
      showFossDialog<void>(
        context: ctx,
        presentation: FossDialogPresentation.centered,
        builder: (context) => const FossDialog(title: Text('Default')),
      ),
    );
    expect(await cardWidth(), 512);
    Navigator.of(ctx).pop();
    await tester.pumpAndSettle();

    unawaited(
      showFossDialog<void>(
        context: ctx,
        presentation: FossDialogPresentation.centered,
        builder: (context) => const FossDialog(
          title: Text('Narrow'),
          style: FossDialogStyle(maxWidth: 400),
        ),
      ),
    );
    expect(await cardWidth(), 400);
  });

  testWidgets('hides the close button and takes a custom icon', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );

    unawaited(
      showFossDialog<void>(
        context: ctx,
        builder: (context) => const FossDialog(
          title: Text('Hidden'),
          showCloseButton: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Close'), findsNothing);
    Navigator.of(ctx).pop();
    await tester.pumpAndSettle();

    unawaited(
      showFossDialog<void>(
        context: ctx,
        builder: (context) => const FossDialog(
          title: Text('Custom'),
          closeIcon: Text('x'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('x'), findsOneWidget);
  });

  testWidgets('a non-dismissible scrim ignores taps', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );

    unawaited(
      showFossDialog<void>(
        context: ctx,
        barrierDismissible: false,
        builder: (context) => const FossDialog(title: Text('Locked')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Locked'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Locked'), findsOneWidget);
  });

  testWidgets('defaults to a full-width bottom sheet', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );

    unawaited(
      showFossDialog<void>(
        context: ctx,
        builder: (context) => const FossDialog(title: Text('Sheet')),
      ),
    );
    await tester.pumpAndSettle();

    final surface = find
        .descendant(
          of: find.byType(FossDialog),
          matching: find.byType(DecoratedBox),
        )
        .first;
    final rect = tester.getRect(surface);
    // Full-bleed and stuck to the bottom edge of the 800x600 test surface.
    expect(rect.width, 800);
    expect(rect.bottom, 600);
  });

  testWidgets('a filled footer draws a bordered bar', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );

    unawaited(
      showFossDialog<void>(
        context: ctx,
        // Centered: the card uses a ShapeDecoration, so the only bordered
        // BoxDecoration is the filled footer bar (the default variant).
        presentation: FossDialogPresentation.centered,
        builder: (context) => FossDialog(
          title: const Text('Filled'),
          actions: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final borderedBar = find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).border != null,
    );
    expect(borderedBar, findsOneWidget);
  });

  testWidgets('reduced motion opens without a transition', (tester) async {
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
      showFossDialog<void>(
        context: ctx,
        builder: (context) => const FossDialog(title: Text('Instant')),
      ),
    );
    // A single pump, no settle: with animations disabled the content is
    // already on screen.
    await tester.pump();
    expect(find.text('Instant'), findsOneWidget);
  });

  group('FossDialogStyle.merge', () {
    test('lays every non-null field of other over this', () {
      const base = FossDialogStyle(
        backgroundColor: Color(0xFF111111),
        borderColor: Color(0xFF222222),
        borderRadius: 8,
        maxWidth: 320,
        titleStyle: TextStyle(fontSize: 10),
        descriptionStyle: TextStyle(fontSize: 11),
      );
      const over = FossDialogStyle(
        maxWidth: 480,
        shadows: [BoxShadow(blurRadius: 4)],
      );

      final merged = base.merge(over);

      expect(merged.backgroundColor, const Color(0xFF111111));
      expect(merged.borderColor, const Color(0xFF222222));
      expect(merged.borderRadius, 8);
      expect(merged.maxWidth, 480);
      expect(merged.shadows, const [BoxShadow(blurRadius: 4)]);
      expect(merged.titleStyle, const TextStyle(fontSize: 10));
      expect(merged.descriptionStyle, const TextStyle(fontSize: 11));
    });

    test('merge(null) returns this', () {
      const base = FossDialogStyle(maxWidth: 320);
      expect(base.merge(null), same(base));
    });
  });
}
