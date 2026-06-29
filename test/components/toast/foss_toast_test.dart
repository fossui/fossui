import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

void main() {
  late BuildContext ctx;

  Widget host() => FossTheme(
    data: FossThemeData.light,
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
}
