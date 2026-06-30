import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

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

  testWidgets('asserts on empty actions', (tester) async {
    expect(
      () => FossAlertDialog(actions: const [], title: const Text('x')),
      throwsAssertionError,
    );
  });
}
