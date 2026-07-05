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

  testWidgets('scrim tap does not dismiss; the action returns a value', (
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

    final pending = showFossAlertDialog<bool>(
      context: ctx,
      builder: (context) => FossAlertDialog(
        title: const Text('Delete account'),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Delete account'), findsOneWidget);

    // Tapping the scrim must not close a non-dismissible alert dialog.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Delete account'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete account'), findsNothing);
    expect(await pending, isTrue);
  });

  testWidgets('renders body, description, and honors a style width', (
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

    unawaited(
      showFossAlertDialog<void>(
        context: ctx,
        builder: (context) => FossAlertDialog(
          title: const Text('Session expired'),
          description: const Text('Sign in again to continue.'),
          content: const Text('Your token lapsed.'),
          style: const FossAlertDialogStyle(maxWidth: 360),
          actions: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Session expired'), findsOneWidget);
    expect(find.text('Sign in again to continue.'), findsOneWidget);
    expect(find.text('Your token lapsed.'), findsOneWidget);
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
      showFossAlertDialog<void>(
        context: ctx,
        builder: (context) => FossAlertDialog(
          title: const Text('Delete account'),
          semanticLabel: 'Delete account alert',
          actions: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Delete account alert'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('back button pops with a null result', (tester) async {
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

    final pending = showFossAlertDialog<bool>(
      context: ctx,
      builder: (context) => FossAlertDialog(
        title: const Text('Discard changes'),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Discard changes'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes'), findsNothing);
    expect(await pending, isNull);
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
      showFossAlertDialog<void>(
        context: ctx,
        builder: (context) => FossAlertDialog(
          title: const Text('Sheet'),
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

    final surface = find
        .descendant(
          of: find.byType(FossAlertDialog),
          matching: find.byType(DecoratedBox),
        )
        .first;
    final rect = tester.getRect(surface);
    expect(rect.width, 800);
    expect(rect.bottom, 600);
  });

  testWidgets('asserts on empty actions', (tester) async {
    expect(
      () => FossAlertDialog(actions: const [], title: const Text('x')),
      throwsAssertionError,
    );
  });

  group('FossAlertDialogStyle.merge', () {
    test('lays every non-null field of other over this', () {
      const base = FossAlertDialogStyle(
        backgroundColor: Color(0xFF111111),
        borderColor: Color(0xFF222222),
        borderRadius: 8,
        maxWidth: 320,
        titleStyle: TextStyle(fontSize: 10),
        descriptionStyle: TextStyle(fontSize: 11),
      );
      const over = FossAlertDialogStyle(
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
      const base = FossAlertDialogStyle(maxWidth: 320);
      expect(base.merge(null), same(base));
    });

    test('is a FossDialogStyle and merge keeps the alert type', () {
      const base = FossAlertDialogStyle(maxWidth: 320);
      expect(base, isA<FossDialogStyle>());
      expect(
        base.merge(const FossAlertDialogStyle(borderRadius: 6)),
        isA<FossAlertDialogStyle>(),
      );
    });
  });
}
