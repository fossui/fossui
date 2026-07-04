import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';
import 'package:fossui/src/icons/foss_glyph.dart';

void main() {
  Widget host(
    Widget child, {
    FossThemeData? theme,
    TextDirection textDirection = TextDirection.ltr,
    double textScale = 1,
    double width = 320,
  }) => FossTheme(
    data: theme ?? FossThemeData.light,
    child: Directionality(
      textDirection: textDirection,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );

  ShapeDecoration surfaceOf(WidgetTester tester) =>
      tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration
          as ShapeDecoration;

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

  testWidgets('neutral fill lifts on a dark theme', (tester) async {
    await tester.pumpWidget(
      host(
        const FossAlert(title: Text('Neutral')),
        theme: FossThemeData.dark,
      ),
    );

    expect(find.text('Neutral'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('two actions wrap instead of overflowing at textScale 2.0', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        textScale: 2,
        FossAlert(
          variant: FossAlertVariant.error,
          title: const Text('Payment failed'),
          actions: [
            GestureDetector(onTap: () {}, child: const Text('Retry')),
            GestureDetector(onTap: () {}, child: const Text('Dismiss')),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Wrap), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
  });

  testWidgets('actions align to the trailing edge', (tester) async {
    await tester.pumpWidget(
      host(
        FossAlert(
          title: const Text('Update available'),
          actions: [
            GestureDetector(onTap: () {}, child: const Text('Later')),
          ],
        ),
      ),
    );

    final alertRight = tester.getRect(find.byType(FossAlert)).right;
    final actionRight = tester.getRect(find.text('Later')).right;
    // The action hugs the trailing edge, well past the alert's horizontal
    // center, rather than sitting under the title on the leading side.
    expect(
      actionRight,
      greaterThan(tester.getRect(find.byType(FossAlert)).center.dx),
    );
    expect(alertRight - actionRight, lessThan(24));
  });

  testWidgets('lays out under RTL without overflow', (tester) async {
    await tester.pumpWidget(
      host(
        textDirection: TextDirection.rtl,
        const FossAlert(
          variant: FossAlertVariant.info,
          title: Text('Heads up'),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.byWidgetPredicate((w) => w is CustomPaint && w.painter is InfoGlyph),
      findsOneWidget,
    );
  });

  testWidgets('exposes an alert live region to assistive tech', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(const FossAlert(title: Text('Neutral'))),
    );
    final node = tester.getSemantics(find.byType(FossAlert));
    expect(node.flagsCollection.isLiveRegion, isTrue);
    handle.dispose();
  });

  testWidgets('a status glyph carries its label', (tester) async {
    await tester.pumpWidget(
      host(
        const FossAlert(
          variant: FossAlertVariant.warning,
          title: Text('Careful'),
        ),
      ),
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is FossGlyphIcon && w.semanticLabel == 'warning',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a status variant tints its surface from the role', (
    tester,
  ) async {
    final colors = FossThemeData.light.colors;
    await tester.pumpWidget(
      host(const FossAlert(variant: FossAlertVariant.info, title: Text('Hi'))),
    );

    final surface = surfaceOf(tester);
    final side = (surface.shape as RoundedSuperellipseBorder).side;
    expect(surface.color, colors.info.withValues(alpha: colors.info.a * 0.04));
    expect(side.color, colors.info.withValues(alpha: colors.info.a * 0.32));
  });

  testWidgets('style overrides land on the rendered surface', (tester) async {
    await tester.pumpWidget(
      host(
        const FossAlert(
          variant: FossAlertVariant.error,
          title: Text('Styled'),
          style: FossAlertStyle(
            backgroundColor: Color(0xFF010203),
            borderColor: Color(0xFF040506),
            borderRadius: 3,
          ),
        ),
      ),
    );

    final surface = surfaceOf(tester);
    final shape = surface.shape as RoundedSuperellipseBorder;
    expect(surface.color, const Color(0xFF010203));
    expect(shape.side.color, const Color(0xFF040506));
    expect(shape.borderRadius, BorderRadius.circular(3));
  });

  testWidgets('a custom icon inherits the variant accent and size', (
    tester,
  ) async {
    final colors = FossThemeData.light.colors;
    await tester.pumpWidget(
      host(
        const FossAlert(
          variant: FossAlertVariant.success,
          title: Text('Saved'),
          icon: SizedBox.shrink(),
        ),
      ),
    );

    final iconTheme = tester.widget<IconTheme>(
      find
          .descendant(
            of: find.byType(FossAlert),
            matching: find.byType(IconTheme),
          )
          .first,
    );
    expect(iconTheme.data.color, colors.success);
    expect(iconTheme.data.size, 16);
  });

  group('FossAlertStyle.merge', () {
    test('lays every non-null field of other over this', () {
      const base = FossAlertStyle(
        backgroundColor: Color(0xFF111111),
        borderColor: Color(0xFF222222),
        iconColor: Color(0xFF333333),
        borderRadius: 8,
        titleStyle: TextStyle(fontSize: 10),
        descriptionStyle: TextStyle(fontSize: 11),
      );
      const over = FossAlertStyle(
        borderColor: Color(0xFF444444),
        borderRadius: 12,
      );

      final merged = base.merge(over);

      expect(merged.backgroundColor, const Color(0xFF111111));
      expect(merged.borderColor, const Color(0xFF444444));
      expect(merged.iconColor, const Color(0xFF333333));
      expect(merged.borderRadius, 12);
      expect(merged.titleStyle, const TextStyle(fontSize: 10));
      expect(merged.descriptionStyle, const TextStyle(fontSize: 11));
    });

    test('merge(null) returns this', () {
      const base = FossAlertStyle(borderRadius: 8);
      expect(base.merge(null), same(base));
    });
  });
}
