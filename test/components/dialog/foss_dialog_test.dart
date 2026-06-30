import 'dart:async';

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

  testWidgets('opens, shows the title, and returns the popped value', (
    tester,
  ) async {
    late BuildContext ctx;
    Future<bool?>? pending;

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

    pending = showFossDialog<bool>(
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
}
