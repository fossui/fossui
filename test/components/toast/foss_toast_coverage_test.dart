import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

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

  testWidgets('a cancelled press on a toast releases the hold', (tester) async {
    await tester.pumpWidget(host());
    showFossToast(
      ctx,
      const FossToast(
        variant: FossToastVariant.info,
        title: Text('Heads up'),
        duration: Duration(minutes: 1),
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Heads up')),
    );
    await tester.pump();
    await gesture.cancel();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Heads up'), findsOneWidget);
  });

  testWidgets('a handle updates then dismisses its toast', (tester) async {
    await tester.pumpWidget(host());
    final handle = showFossToast(
      ctx,
      const FossToast(
        variant: FossToastVariant.info,
        title: Text('First'),
        duration: Duration(minutes: 1),
      ),
    );
    await tester.pumpAndSettle();

    handle.update(
      const FossToast(
        variant: FossToastVariant.info,
        title: Text('Second'),
        duration: Duration(minutes: 1),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);

    handle.dismiss();
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsNothing);
  });
}
