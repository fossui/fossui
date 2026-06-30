import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

void main() {
  Widget host(
    Widget child, {
    FossThemeData? theme,
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
  }) => FossTheme(
    data: theme ?? FossThemeData.light,
    child: Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );

  Color lineColor(WidgetTester tester) => tester
      .widget<ColoredBox>(
        find.descendant(
          of: find.byType(FossSeparator),
          matching: find.byType(ColoredBox),
        ),
      )
      .color;

  group('FossSeparator', () {
    testWidgets('horizontal fills width at 1px tall', (tester) async {
      await tester.pumpWidget(
        host(const SizedBox(width: 200, child: FossSeparator())),
      );

      final size = tester.getSize(find.byType(FossSeparator));
      expect(size, const Size(200, 1));
    });

    testWidgets('vertical fills height at 1px wide', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            height: 120,
            child: FossSeparator(
              orientation: FossSeparatorOrientation.vertical,
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(FossSeparator));
      expect(size, const Size(1, 120));
    });

    testWidgets('paints the border role', (tester) async {
      await tester.pumpWidget(host(const FossSeparator()));
      expect(lineColor(tester), FossThemeData.light.colors.border);
    });

    testWidgets('resolves the dark border role', (tester) async {
      await tester.pumpWidget(
        host(const FossSeparator(), theme: FossThemeData.dark),
      );
      expect(lineColor(tester), FossThemeData.dark.colors.border);
    });

    testWidgets('decorative by default is hidden from semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const FossSeparator()));

      expect(
        find.descendant(
          of: find.byType(FossSeparator),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('decorative false exposes a semantics node', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const FossSeparator(decorative: false)),
      );

      expect(
        find.descendant(
          of: find.byType(FossSeparator),
          matching: find.byType(Semantics),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(FossSeparator),
          matching: find.byType(ExcludeSemantics),
        ),
        findsNothing,
      );
      handle.dispose();
    });

    testWidgets('stays 1px under 2x text scale', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(width: 200, child: FossSeparator()),
          textScale: 2,
        ),
      );
      expect(tester.getSize(find.byType(FossSeparator)).height, 1);
    });

    testWidgets('is symmetric under RTL', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(width: 200, child: FossSeparator()),
          direction: TextDirection.rtl,
        ),
      );
      expect(tester.getSize(find.byType(FossSeparator)), const Size(200, 1));
    });
  });
}
