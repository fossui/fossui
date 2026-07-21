import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

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

  Text renderedText(WidgetTester tester) =>
      tester.widget<Text>(find.byType(Text));

  TextStyle styleOf(WidgetTester tester) =>
      renderedText(tester).style ?? const TextStyle();

  group('type scale', () {
    const cases = {
      FossTextSize.xs: 12.0,
      FossTextSize.sm: 14.0,
      FossTextSize.base: 16.0,
      FossTextSize.lg: 18.0,
      FossTextSize.xl: 20.0,
      FossTextSize.xl2: 24.0,
    };

    for (final MapEntry(key: size, value: fontSize) in cases.entries) {
      testWidgets('$size resolves to $fontSize', (tester) async {
        await tester.pumpWidget(host(FossText('T', size: size)));
        expect(styleOf(tester).fontSize, fontSize);
      });
    }

    testWidgets('every step carries the bundled family', (tester) async {
      for (final size in FossTextSize.values) {
        await tester.pumpWidget(host(FossText('T', size: size)));
        expect(styleOf(tester).fontFamily, 'packages/fossui/Geist');
      }
    });

    testWidgets('defaults to base', (tester) async {
      await tester.pumpWidget(host(const FossText('T')));
      expect(styleOf(tester).fontSize, 16);
    });
  });

  group('weight', () {
    const cases = {
      FossTextWeight.regular: FontWeight.w400,
      FossTextWeight.medium: FontWeight.w500,
      FossTextWeight.semibold: FontWeight.w600,
      FossTextWeight.bold: FontWeight.w700,
    };

    for (final MapEntry(key: weight, value: fontWeight) in cases.entries) {
      testWidgets('$weight resolves to $fontWeight', (tester) async {
        await tester.pumpWidget(host(FossText('T', weight: weight)));
        expect(styleOf(tester).fontWeight, fontWeight);
      });
    }

    testWidgets('defaults to regular', (tester) async {
      await tester.pumpWidget(host(const FossText('T')));
      expect(styleOf(tester).fontWeight, FontWeight.w400);
    });
  });

  group('color role', () {
    final colors = FossThemeData.light.colors;
    final cases = {
      FossTextColor.foreground: colors.foreground,
      FossTextColor.mutedForeground: colors.mutedForeground,
      FossTextColor.primary: colors.primary,
      FossTextColor.destructive: colors.destructive,
    };

    for (final MapEntry(key: role, value: color) in cases.entries) {
      testWidgets('$role resolves to its token', (tester) async {
        await tester.pumpWidget(host(FossText('T', color: role)));
        expect(styleOf(tester).color, color);
      });
    }

    testWidgets('null color defaults to the foreground role', (tester) async {
      await tester.pumpWidget(host(const FossText('T')));
      expect(styleOf(tester).color, FossThemeData.light.colors.foreground);
    });

    testWidgets('the default color follows the theme (dark)', (tester) async {
      await tester.pumpWidget(
        host(const FossText('T'), theme: FossThemeData.dark),
      );
      expect(styleOf(tester).color, FossThemeData.dark.colors.foreground);
    });

    testWidgets('a set role resolves against the active theme (dark)', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FossText('T', color: FossTextColor.primary),
          theme: FossThemeData.dark,
        ),
      );
      expect(styleOf(tester).color, FossThemeData.dark.colors.primary);
    });
  });

  group('named constructors', () {
    // A runtime string keeps each construction non-const, so the named
    // constructor body executes (and is covered) rather than folding to a
    // compile-time constant.
    final t = 'T'.substring(0);

    void expectPreset(
      WidgetTester tester,
      double fontSize,
      FontWeight fontWeight,
    ) {
      final style = styleOf(tester);
      expect(style.fontSize, fontSize);
      expect(style.fontWeight, fontWeight);
    }

    testWidgets('caption is xs / regular', (tester) async {
      await tester.pumpWidget(host(FossText.caption(t)));
      expectPreset(tester, 12, FontWeight.w400);
    });

    testWidgets('body is sm / regular', (tester) async {
      await tester.pumpWidget(host(FossText.body(t)));
      expectPreset(tester, 14, FontWeight.w400);
    });

    testWidgets('label is sm / medium', (tester) async {
      await tester.pumpWidget(host(FossText.label(t)));
      expectPreset(tester, 14, FontWeight.w500);
    });

    testWidgets('title is lg / semibold', (tester) async {
      await tester.pumpWidget(host(FossText.title(t)));
      expectPreset(tester, 18, FontWeight.w600);
    });

    testWidgets('heading is xl / semibold', (tester) async {
      await tester.pumpWidget(host(FossText.heading(t)));
      expectPreset(tester, 20, FontWeight.w600);
    });

    testWidgets('display is xl2 / bold', (tester) async {
      await tester.pumpWidget(host(FossText.display(t)));
      expectPreset(tester, 24, FontWeight.w700);
    });

    testWidgets('a preset still takes a color role', (tester) async {
      await tester.pumpWidget(
        host(const FossText.body('T', color: FossTextColor.mutedForeground)),
      );
      expect(styleOf(tester).color, FossThemeData.light.colors.mutedForeground);
    });
  });

  group('style override', () {
    testWidgets('wins on the fields it sets', (tester) async {
      await tester.pumpWidget(
        host(
          const FossText(
            'T',
            size: FossTextSize.sm,
            color: FossTextColor.foreground,
            style: TextStyle(color: Color(0xFF00FF00), fontSize: 99),
          ),
        ),
      );
      final style = styleOf(tester);
      expect(style.color, const Color(0xFF00FF00));
      expect(style.fontSize, 99);
    });

    testWidgets('leaves untouched fields resolved', (tester) async {
      await tester.pumpWidget(
        host(
          const FossText(
            'T',
            size: FossTextSize.lg,
            style: TextStyle(letterSpacing: 5),
          ),
        ),
      );
      final style = styleOf(tester);
      expect(style.fontSize, 18);
      expect(style.letterSpacing, 5);
    });
  });

  group('render and accessibility', () {
    testWidgets('renders the string', (tester) async {
      await tester.pumpWidget(host(const FossText('Hello')));
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('semanticsLabel replaces the read-out', (tester) async {
      await tester.pumpWidget(
        host(const FossText('12:30', semanticsLabel: 'half past twelve')),
      );
      expect(renderedText(tester).semanticsLabel, 'half past twelve');
    });

    testWidgets('passes maxLines and overflow through', (tester) async {
      await tester.pumpWidget(
        host(
          const FossText(
            'a long string that would wrap',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
      final text = renderedText(tester);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('renders under textScale 2.0', (tester) async {
      await tester.pumpWidget(
        host(const FossText('T', size: FossTextSize.xl2), textScale: 2),
      );
      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('renders right-to-left', (tester) async {
      await tester.pumpWidget(
        host(const FossText('مرحبا'), direction: TextDirection.rtl),
      );
      expect(find.text('مرحبا'), findsOneWidget);
    });

    testWidgets('header: true marks the text as a heading', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const FossText.title('Settings', header: true)),
      );
      expect(
        tester.getSemantics(find.text('Settings')),
        isSemantics(isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('header defaults to false (no heading flag)', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const FossText.title('Settings')));
      expect(
        tester.getSemantics(find.text('Settings')),
        isSemantics(isHeader: false),
      );
      handle.dispose();
    });
  });
}
