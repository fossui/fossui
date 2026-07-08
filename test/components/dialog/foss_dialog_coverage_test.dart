import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

void main() {
  Widget host(Widget child, {FossThemeData? theme}) => FossTheme(
    data: theme ?? FossThemeData.light,
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(400, 640)),
        child: Center(child: child),
      ),
    ),
  );

  testWidgets('standalone dialog falls back to the centered presentation', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const FossDialog(title: Text('Standalone'))),
    );

    expect(find.text('Standalone'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the rim repaints across a theme change', (tester) async {
    await tester.pumpWidget(
      host(const FossDialog(title: Text('Themed'))),
    );
    // A same-theme rebuild reconstructs the painter with equal fields, so
    // shouldRepaint evaluates every operand rather than short-circuiting.
    await tester.pumpWidget(
      host(const FossDialog(title: Text('Themed'))),
    );
    await tester.pumpWidget(
      host(const FossDialog(title: Text('Themed')), theme: FossThemeData.dark),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('the close button pops the route', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      FossTheme(
        data: FossThemeData.light,
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
      showFossDialog<void>(
        context: ctx,
        builder: (context) => const FossDialog(title: Text('Closable')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Closable'), findsOneWidget);

    // A cancelled press resets the pressed state without popping.
    final press = await tester.startGesture(
      tester.getCenter(find.bySemanticsLabel('Close')),
    );
    await tester.pump();
    await press.cancel();
    await tester.pump();
    expect(find.text('Closable'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Closable'), findsNothing);
  });

  testWidgets('an open dialog survives an ancestor rebuild', (tester) async {
    late BuildContext ctx;
    Widget app() => FossTheme(
      data: FossThemeData.light,
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
    );

    await tester.pumpWidget(app());
    unawaited(
      showFossDialog<void>(
        context: ctx,
        builder: (context) => const FossDialog(title: Text('Persistent')),
      ),
    );
    await tester.pumpAndSettle();

    // Rebuild the whole app so the route rebuilds its presentation scope.
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.text('Persistent'), findsOneWidget);
  });
}
