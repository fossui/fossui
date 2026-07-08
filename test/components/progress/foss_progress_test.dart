import 'package:flutter/semantics.dart';
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

  // The painted fill width as a fraction of the track width. Measures the
  // rendered geometry, not the widthFactor property, so a zero-width fill is
  // caught.
  // The painted fill is the inner DecoratedBox (the leading band); the track is
  // the outer one.
  final fillBox = find
      .descendant(
        of: find.byType(FossProgress),
        matching: find.byType(DecoratedBox),
      )
      .last;

  double fillFactor(WidgetTester tester) {
    final trackWidth = tester.getSize(find.byType(FossProgress)).width;
    return tester.getSize(fillBox).width / trackWidth;
  }

  Color shapeColor(WidgetTester tester, {required bool fill}) {
    final boxes = find.descendant(
      of: find.byType(FossProgress),
      matching: find.byType(DecoratedBox),
    );
    final box = tester.widget<DecoratedBox>(fill ? boxes.last : boxes.first);
    return (box.decoration as ShapeDecoration).color ?? const Color(0x00000000);
  }

  group('FossProgressStyle.merge', () {
    test('lays every non-null field of other over this', () {
      const base = FossProgressStyle(
        trackColor: Color(0xFF111111),
        fillColor: Color(0xFF222222),
      );
      const over = FossProgressStyle(fillColor: Color(0xFF333333));

      final merged = base.merge(over);

      expect(merged.trackColor, const Color(0xFF111111));
      expect(merged.fillColor, const Color(0xFF333333));
    });

    test('merge(null) returns this', () {
      const base = FossProgressStyle(fillColor: Color(0xFF222222));
      expect(base.merge(null), same(base));
    });
  });

  group('fill fraction', () {
    testWidgets('renders at the given value', (tester) async {
      await tester.pumpWidget(host(const FossProgress(value: 0.4)));
      await tester.pumpAndSettle();
      expect(fillFactor(tester), moreOrLessEquals(0.4));
    });

    testWidgets('empty and full', (tester) async {
      await tester.pumpWidget(host(const FossProgress(value: 0)));
      await tester.pumpAndSettle();
      expect(fillFactor(tester), 0);

      await tester.pumpWidget(host(const FossProgress(value: 1)));
      await tester.pumpAndSettle();
      expect(fillFactor(tester), 1);
    });

    testWidgets('clamps out-of-range input', (tester) async {
      await tester.pumpWidget(host(const FossProgress(value: 1.8)));
      await tester.pumpAndSettle();
      expect(fillFactor(tester), 1);

      await tester.pumpWidget(host(const FossProgress(value: -0.5)));
      await tester.pumpAndSettle();
      expect(fillFactor(tester), 0);
    });

    testWidgets('constructs from a runtime value', (tester) async {
      for (final v in <double>[0, 0.5, 1]) {
        await tester.pumpWidget(host(FossProgress(value: v)));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('animates toward a new value over the motion duration', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FossProgress(value: 0.2)));
      await tester.pumpAndSettle();
      expect(fillFactor(tester), moreOrLessEquals(0.2));

      await tester.pumpWidget(host(const FossProgress(value: 0.8)));
      await tester.pump(const Duration(milliseconds: 100));
      final mid = fillFactor(tester);
      expect(mid, greaterThan(0.2));
      expect(mid, lessThan(0.8));

      await tester.pumpAndSettle();
      expect(fillFactor(tester), moreOrLessEquals(0.8));
    });

    testWidgets('reduced motion jumps to the new value', (tester) async {
      await tester.pumpWidget(
        host(const FossProgress(value: 0.2), reduceMotion: true),
      );
      await tester.pump();
      await tester.pumpWidget(
        host(const FossProgress(value: 0.9), reduceMotion: true),
      );
      // One frame: no scheduled animation, so the fill is already at the value.
      await tester.pump();
      expect(fillFactor(tester), moreOrLessEquals(0.9));
    });
  });

  group('label row', () {
    testWidgets('none by default', (tester) async {
      await tester.pumpWidget(host(const FossProgress(value: 0.5)));
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('label only', (tester) async {
      await tester.pumpWidget(
        host(const FossProgress(value: 0.5, label: 'Uploading')),
      );
      expect(find.text('Uploading'), findsOneWidget);
    });

    testWidgets('value only', (tester) async {
      await tester.pumpWidget(
        host(const FossProgress(value: 0.5, valueLabel: '50%')),
      );
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('both', (tester) async {
      await tester.pumpWidget(
        host(
          const FossProgress(value: 0.5, label: 'Uploading', valueLabel: '50%'),
        ),
      );
      expect(find.text('Uploading'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('exposes value and label on the bar', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const FossProgress(value: 0.4, label: 'Uploading')),
      );
      await tester.pumpAndSettle();

      final data = tester
          .getSemantics(find.byType(FossProgress))
          .getSemanticsData();
      expect(data.role, SemanticsRole.progressBar);
      expect(data.label, 'Uploading');
      expect(data.value, '0.40');
      expect(data.minValue, '0');
      expect(data.maxValue, '1');
      handle.dispose();
    });

    testWidgets('falls back to semanticsLabel with no visible label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const FossProgress(value: 0.4, semanticsLabel: 'Upload progress')),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(FossProgress)),
        isSemantics(value: '0.40', label: 'Upload progress'),
      );
      handle.dispose();
    });

    testWidgets('value text is not double-announced', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const FossProgress(value: 0.5, valueLabel: '50%')),
      );
      await tester.pumpAndSettle();

      // The '50%' is the bar's semantic value, not a separate text node.
      expect(find.bySemanticsLabel('50%'), findsNothing);
      handle.dispose();
    });
  });

  group('direction and theme', () {
    testWidgets('fill leads from the end in RTL', (tester) async {
      await tester.pumpWidget(
        host(const FossProgress(value: 0.3), direction: TextDirection.rtl),
      );
      await tester.pumpAndSettle();
      final fill = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fill.alignment.resolve(TextDirection.rtl), Alignment.centerRight);
      // The painted band is pinned to the trailing (right) edge in RTL, and is
      // narrower than the track.
      final track = tester.getRect(find.byType(FossProgress));
      final band = tester.getRect(fillBox);
      expect(band.right, moreOrLessEquals(track.right, epsilon: 0.5));
      expect(band.width, lessThan(track.width));
    });

    testWidgets('track and fill resolve their roles in dark', (tester) async {
      await tester.pumpWidget(
        host(const FossProgress(value: 0.5), theme: FossThemeData.dark),
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
          const FossProgress(
            value: 0.5,
            style: FossProgressStyle(
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
          const FossProgress(
            value: 0.5,
            label: 'Uploading',
            valueLabel: '50%',
            style: FossProgressStyle(
              labelStyle: TextStyle(color: Color(0xFFAA0000)),
              valueLabelStyle: TextStyle(color: Color(0xFF00AA00)),
            ),
          ),
        ),
      );

      expect(
        tester.widget<Text>(find.text('Uploading')).style?.color,
        const Color(0xFFAA0000),
      );
      expect(
        tester.widget<Text>(find.text('50%')).style?.color,
        const Color(0xFF00AA00),
      );
    });
  });

  group('geometry and type', () {
    testWidgets('the track holds its 6px height', (tester) async {
      await tester.pumpWidget(host(const FossProgress(value: 0.5)));
      await tester.pumpAndSettle();

      expect(tester.getSize(fillBox).height, 6);
    });

    testWidgets('an 8px gap separates the row from the track', (tester) async {
      await tester.pumpWidget(
        host(
          const FossProgress(
            value: 0.5,
            label: 'Uploading',
            valueLabel: '50%',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rowBottom = tester.getRect(find.byType(Row)).bottom;
      final track = find
          .descendant(
            of: find.byType(FossProgress),
            matching: find.byType(DecoratedBox),
          )
          .first;
      expect(
        tester.getRect(track).top - rowBottom,
        moreOrLessEquals(8, epsilon: 0.5),
      );
    });

    testWidgets('the value uses tabular figures', (tester) async {
      await tester.pumpWidget(
        host(const FossProgress(value: 0.5, valueLabel: '50%')),
      );

      expect(
        tester.widget<Text>(find.text('50%')).style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });

  group('overflow', () {
    testWidgets('a long label ellipsizes at 2x text scale', (tester) async {
      const label = 'Uploading a very large archive to the remote server now';
      await tester.pumpWidget(
        host(
          const FossProgress(value: 0.5, label: label, valueLabel: '50%'),
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.text(label));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });
}
