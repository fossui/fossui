import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

void main() {
  Widget host(
    Widget child, {
    FossThemeData? theme,
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    bool reduceMotion = false,
  }) => FossTheme(
    data: theme ?? FossThemeData.light,
    child: Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 320, child: child),
        ),
      ),
    ),
  );

  // The painted fill is the inner DecoratedBox (the leading band); the track is
  // the outer one. Measuring rendered geometry catches a zero-width fill.
  final fillBox = find
      .descendant(
        of: find.byType(FossMeter),
        matching: find.byType(DecoratedBox),
      )
      .last;

  double fillFactor(WidgetTester tester) {
    final trackWidth = tester.getSize(find.byType(FossMeter)).width;
    return tester.getSize(fillBox).width / trackWidth;
  }

  Color shapeColor(WidgetTester tester, {required bool fill}) {
    final boxes = find.descendant(
      of: find.byType(FossMeter),
      matching: find.byType(DecoratedBox),
    );
    final box = tester.widget<DecoratedBox>(fill ? boxes.last : boxes.first);
    return (box.decoration as ShapeDecoration).color ?? const Color(0x00000000);
  }

  group('FossMeterStyle.merge', () {
    test('lays every non-null field of other over this', () {
      const base = FossMeterStyle(
        trackColor: Color(0xFF111111),
        fillColor: Color(0xFF222222),
      );
      const over = FossMeterStyle(fillColor: Color(0xFF333333));

      final merged = base.merge(over);

      expect(merged.trackColor, const Color(0xFF111111));
      expect(merged.fillColor, const Color(0xFF333333));
    });

    test('merge(null) returns this', () {
      const base = FossMeterStyle(fillColor: Color(0xFF222222));
      expect(base.merge(null), same(base));
    });
  });

  group('fill fraction', () {
    testWidgets('maps the value onto the default range', (tester) async {
      await tester.pumpWidget(host(const FossMeter(value: 40)));
      await tester.pumpAndSettle();
      expect(fillFactor(tester), moreOrLessEquals(0.4));
    });

    testWidgets('maps the value onto a custom range', (tester) async {
      await tester.pumpWidget(host(const FossMeter(value: 3, max: 5)));
      await tester.pumpAndSettle();
      expect(fillFactor(tester), moreOrLessEquals(0.6));
    });

    testWidgets('empty and full', (tester) async {
      await tester.pumpWidget(host(const FossMeter(value: 0)));
      await tester.pumpAndSettle();
      expect(fillFactor(tester), 0);

      await tester.pumpWidget(host(const FossMeter(value: 100)));
      await tester.pumpAndSettle();
      expect(fillFactor(tester), 1);
    });

    testWidgets('clamps out-of-range input', (tester) async {
      await tester.pumpWidget(host(const FossMeter(value: 180)));
      await tester.pumpAndSettle();
      expect(fillFactor(tester), 1);

      await tester.pumpWidget(host(const FossMeter(value: -50)));
      await tester.pumpAndSettle();
      expect(fillFactor(tester), 0);
    });

    testWidgets('a zero-width range reads empty', (tester) async {
      await tester.pumpWidget(
        host(const FossMeter(value: 5, min: 5, max: 5)),
      );
      await tester.pumpAndSettle();
      expect(fillFactor(tester), 0);
    });

    testWidgets('a non-finite value reads empty, not full', (tester) async {
      await tester.pumpWidget(host(const FossMeter(value: double.nan)));
      await tester.pumpAndSettle();
      expect(fillFactor(tester), 0);
    });

    testWidgets('animates toward a new value over the motion duration', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FossMeter(value: 20)));
      await tester.pumpAndSettle();
      expect(fillFactor(tester), moreOrLessEquals(0.2));

      await tester.pumpWidget(host(const FossMeter(value: 80)));
      await tester.pump(const Duration(milliseconds: 100));
      final mid = fillFactor(tester);
      expect(mid, greaterThan(0.2));
      expect(mid, lessThan(0.8));

      await tester.pumpAndSettle();
      expect(fillFactor(tester), moreOrLessEquals(0.8));
    });

    testWidgets('reduced motion jumps to the new value', (tester) async {
      await tester.pumpWidget(
        host(const FossMeter(value: 20), reduceMotion: true),
      );
      await tester.pump();
      await tester.pumpWidget(
        host(const FossMeter(value: 90), reduceMotion: true),
      );
      await tester.pump();
      expect(fillFactor(tester), moreOrLessEquals(0.9));
    });
  });

  group('value text', () {
    testWidgets('defaults to a percentage of the range', (tester) async {
      await tester.pumpWidget(host(const FossMeter(value: 40)));
      expect(find.text('40%'), findsOneWidget);
    });

    testWidgets('percentage tracks a custom range', (tester) async {
      await tester.pumpWidget(
        host(const FossMeter(value: 3, max: 5)),
      );
      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('a formatter overrides the default text', (tester) async {
      await tester.pumpWidget(
        host(
          FossMeter(
            value: 3,
            max: 5,
            formatValue: (value, min, max) => '$value of $max',
          ),
        ),
      );
      expect(find.text('3 of 5'), findsOneWidget);
    });

    testWidgets('uses tabular figures', (tester) async {
      await tester.pumpWidget(host(const FossMeter(value: 40)));
      expect(
        tester.widget<Text>(find.text('40%')).style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });

  group('label row', () {
    testWidgets('shows the value by default', (tester) async {
      await tester.pumpWidget(host(const FossMeter(value: 40)));
      expect(find.text('40%'), findsOneWidget);
    });

    testWidgets('label and value', (tester) async {
      await tester.pumpWidget(
        host(const FossMeter(value: 40, label: 'Storage')),
      );
      expect(find.text('Storage'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
    });

    testWidgets('label only when the value is hidden', (tester) async {
      await tester.pumpWidget(
        host(const FossMeter(value: 40, label: 'Storage', showValue: false)),
      );
      expect(find.text('Storage'), findsOneWidget);
      expect(find.text('40%'), findsNothing);
    });

    testWidgets('a bare track when label and value are both off', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const FossMeter(value: 40, showValue: false)),
      );
      expect(find.byType(Text), findsNothing);
    });
  });

  group('accessibility', () {
    testWidgets('exposes value, range, and label on the gauge', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const FossMeter(value: 40, label: 'Storage')),
      );
      await tester.pumpAndSettle();

      final data = tester
          .getSemantics(find.byType(FossMeter))
          .getSemanticsData();
      expect(data.label, 'Storage');
      expect(data.value, '40');
      expect(data.minValue, '0');
      expect(data.maxValue, '100');
      handle.dispose();
    });

    testWidgets('falls back to semanticsLabel with no visible label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const FossMeter(
            value: 40,
            showValue: false,
            semanticsLabel: 'Disk usage',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(FossMeter)),
        isSemantics(value: '40', label: 'Disk usage'),
      );
      handle.dispose();
    });

    testWidgets('value text is not double-announced', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const FossMeter(value: 50)));
      await tester.pumpAndSettle();

      // The '50%' is the gauge's semantic value, not a separate text node.
      expect(find.bySemanticsLabel('50%'), findsNothing);
      handle.dispose();
    });
  });

  group('direction and theme', () {
    testWidgets('fill leads from the end in RTL', (tester) async {
      await tester.pumpWidget(
        host(const FossMeter(value: 30), direction: TextDirection.rtl),
      );
      await tester.pumpAndSettle();
      final fill = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fill.alignment.resolve(TextDirection.rtl), Alignment.centerRight);

      final track = tester.getRect(find.byType(FossMeter));
      final band = tester.getRect(fillBox);
      expect(band.right, moreOrLessEquals(track.right, epsilon: 0.5));
      expect(band.width, lessThan(track.width));
    });

    testWidgets('track and fill resolve their roles in dark', (tester) async {
      await tester.pumpWidget(
        host(const FossMeter(value: 50), theme: FossThemeData.dark),
      );
      await tester.pumpAndSettle();
      expect(shapeColor(tester, fill: false), FossThemeData.dark.colors.input);
      expect(shapeColor(tester, fill: true), FossThemeData.dark.colors.primary);
    });
  });

  group('style through build', () {
    testWidgets('track and fill colors follow the override', (tester) async {
      await tester.pumpWidget(
        host(
          const FossMeter(
            value: 50,
            style: FossMeterStyle(
              trackColor: Color(0xFF102030),
              fillColor: Color(0xFF00FF00),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(shapeColor(tester, fill: false), const Color(0xFF102030));
      expect(shapeColor(tester, fill: true), const Color(0xFF00FF00));
    });

    testWidgets('label and value text styles follow the override', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FossMeter(
            value: 50,
            label: 'Storage',
            style: FossMeterStyle(
              labelStyle: TextStyle(color: Color(0xFFAA0000)),
              valueStyle: TextStyle(color: Color(0xFF00AA00)),
            ),
          ),
        ),
      );

      expect(
        tester.widget<Text>(find.text('Storage')).style?.color,
        const Color(0xFFAA0000),
      );
      expect(
        tester.widget<Text>(find.text('50%')).style?.color,
        const Color(0xFF00AA00),
      );
    });
  });

  group('geometry', () {
    testWidgets('the track holds its 8px height', (tester) async {
      await tester.pumpWidget(host(const FossMeter(value: 50)));
      await tester.pumpAndSettle();
      expect(tester.getSize(fillBox).height, 8);
    });

    testWidgets('an 8px gap separates the row from the track', (tester) async {
      await tester.pumpWidget(
        host(const FossMeter(value: 50, label: 'Storage')),
      );
      await tester.pumpAndSettle();

      final rowBottom = tester.getRect(find.byType(Row)).bottom;
      final track = find
          .descendant(
            of: find.byType(FossMeter),
            matching: find.byType(DecoratedBox),
          )
          .first;
      expect(
        tester.getRect(track).top - rowBottom,
        moreOrLessEquals(8, epsilon: 0.5),
      );
    });
  });

  group('overflow', () {
    testWidgets('a long label ellipsizes at 2x text scale', (tester) async {
      const label = 'Storage used across every connected device and backup';
      await tester.pumpWidget(
        host(const FossMeter(value: 50, label: label), textScale: 2),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.text(label));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });
}
