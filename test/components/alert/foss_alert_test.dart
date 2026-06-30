import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

void main() {
  Widget host(Widget child) => FossTheme(
    data: FossThemeData.light,
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 320, child: child),
      ),
    ),
  );

  testWidgets('renders title, description, and an action', (tester) async {
    await tester.pumpWidget(
      host(
        FossAlert(
          variant: FossAlertVariant.warning,
          title: const Text('Storage almost full'),
          description: const Text('Free up space.'),
          actions: [
            GestureDetector(onTap: () {}, child: const Text('Upgrade')),
          ],
        ),
      ),
    );

    expect(find.text('Storage almost full'), findsOneWidget);
    expect(find.text('Free up space.'), findsOneWidget);
    expect(find.text('Upgrade'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every variant builds without overflow', (tester) async {
    for (final variant in FossAlertVariant.values) {
      await tester.pumpWidget(
        host(FossAlert(variant: variant, title: Text(variant.name))),
      );
      expect(find.text(variant.name), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
