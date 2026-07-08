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
        type: FossToastType.info,
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
}
