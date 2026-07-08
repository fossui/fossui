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
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 320, child: child),
        ),
      ),
    ),
  );

  // The Padding that immediately wraps the slot whose child is [text].
  EdgeInsets slotPadding(WidgetTester tester, String text) {
    final padding = tester.widget<Padding>(
      find.ancestor(of: find.text(text), matching: find.byType(Padding)).first,
    );
    return padding.padding as EdgeInsets;
  }

  // The card's surface decoration: the outer DecoratedBox.
  ShapeDecoration surface(WidgetTester tester) =>
      tester
              .widget<DecoratedBox>(
                find
                    .descendant(
                      of: find.byType(FossCard),
                      matching: find.byType(DecoratedBox),
                    )
                    .first,
              )
              .decoration
          as ShapeDecoration;

  group('FossCardStyle.merge', () {
    test('lays every non-null field of other over this', () {
      const base = FossCardStyle(
        borderRadius: 8,
        borderColor: Color(0xFF111111),
      );
      const over = FossCardStyle(borderRadius: 16);

      final merged = base.merge(over);

      expect(merged.borderRadius, 16);
      expect(merged.borderColor, const Color(0xFF111111));
    });

    test('returns this unchanged when other is null', () {
      const base = FossCardStyle(borderRadius: 12);
      expect(base.merge(null), same(base));
    });
  });

  testWidgets('renders every slot', (tester) async {
    await tester.pumpWidget(
      host(
        const FossCard(
          title: Text('Project'),
          description: Text('Manage settings.'),
          action: Text('Add'),
          content: Text('body'),
          footer: Text('footer'),
        ),
      ),
    );

    for (final t in ['Project', 'Manage settings.', 'Add', 'body', 'footer']) {
      expect(find.text(t), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a card with only content is valid', (tester) async {
    await tester.pumpWidget(host(const FossCard(content: Text('body'))));

    expect(find.text('body'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the rim repaints when the card rebuilds', (tester) async {
    // Rebuilding with new content but the same theme keeps the rim's color,
    // radius, and lit edge equal, so shouldRepaint runs its full comparison.
    for (final label in <String>['one', 'two']) {
      await tester.pumpWidget(host(FossCard(content: Text(label))));
    }

    expect(find.text('two'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lone content keeps the full inset on every side', (
    tester,
  ) async {
    await tester.pumpWidget(host(const FossCard(content: Text('body'))));

    expect(slotPadding(tester, 'body'), const EdgeInsets.all(24));
  });

  testWidgets('the seam between stacked slots collapses', (tester) async {
    await tester.pumpWidget(
      host(
        const FossCard(
          title: Text('Project'),
          content: Text('body'),
          footer: Text('footer'),
        ),
      ),
    );

    // Header bottom tightens to 16 above content; content drops both touching
    // edges to 0; footer top tightens to 16 below content.
    expect(
      slotPadding(tester, 'Project'),
      const EdgeInsets.fromLTRB(24, 24, 24, 16),
    );
    expect(
      slotPadding(tester, 'body'),
      const EdgeInsets.fromLTRB(24, 0, 24, 0),
    );
    expect(
      slotPadding(tester, 'footer'),
      const EdgeInsets.fromLTRB(24, 16, 24, 24),
    );
  });

  testWidgets('the action pins trailing and mirrors in RTL', (tester) async {
    Future<void> pump(TextDirection direction) => tester.pumpWidget(
      host(
        const FossCard(title: Text('Project'), action: Text('Add')),
        direction: direction,
      ),
    );

    await pump(TextDirection.ltr);
    expect(
      tester.getCenter(find.text('Add')).dx,
      greaterThan(tester.getCenter(find.text('Project')).dx),
    );

    await pump(TextDirection.rtl);
    expect(
      tester.getCenter(find.text('Add')).dx,
      lessThan(tester.getCenter(find.text('Project')).dx),
    );
  });

  testWidgets('dark surface builds', (tester) async {
    await tester.pumpWidget(
      host(
        const FossCard(title: Text('Project'), content: Text('body')),
        theme: FossThemeData.dark,
      ),
    );

    expect(find.text('Project'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grows with text at 2x scale without overflow', (tester) async {
    await tester.pumpWidget(
      host(
        const FossCard(
          title: Text('Project'),
          description: Text('Manage your settings and configuration.'),
          content: Text('body'),
        ),
        textScale: 2,
      ),
    );

    expect(tester.takeException(), isNull);
  });

  group('surface', () {
    testWidgets('resolves the card, border, radius, and shadow tokens', (
      tester,
    ) async {
      const theme = FossThemeData.light;
      await tester.pumpWidget(host(const FossCard(content: Text('body'))));

      final dec = surface(tester);
      expect(dec.color, theme.colors.card);
      expect(dec.shadows, theme.shadows.xs);
      final shape = dec.shape as RoundedSuperellipseBorder;
      expect(shape.side.color, theme.colors.border);
      expect(shape.borderRadius, BorderRadius.circular(theme.radii.xl2));
    });

    testWidgets('style overrides drive the surface through build', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FossCard(
            content: Text('body'),
            style: FossCardStyle(
              backgroundColor: Color(0xFF102030),
              borderColor: Color(0xFF00FF00),
              borderRadius: 4,
              shadows: [BoxShadow(color: Color(0x22000000), blurRadius: 7)],
            ),
          ),
        ),
      );

      final dec = surface(tester);
      expect(dec.color, const Color(0xFF102030));
      expect(dec.shadows, const [
        BoxShadow(color: Color(0x22000000), blurRadius: 7),
      ]);
      final shape = dec.shape as RoundedSuperellipseBorder;
      expect(shape.side.color, const Color(0xFF00FF00));
      expect(shape.borderRadius, BorderRadius.circular(4));
    });

    testWidgets('a zero border radius builds without a negative rim', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FossCard(
            content: Text('body'),
            style: FossCardStyle(borderRadius: 0),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('text styles', () {
    testWidgets('the title is semibold 18 on the card foreground', (
      tester,
    ) async {
      TextStyle? style;
      await tester.pumpWidget(
        host(
          FossCard(
            title: Builder(
              builder: (context) {
                style = DefaultTextStyle.of(context).style;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(style?.color, FossThemeData.light.colors.cardForeground);
      expect(style?.fontWeight, FontWeight.w600);
      expect(style?.fontSize, 18);
      expect(style?.height, 1);
    });

    testWidgets('the description is 14 on the muted foreground', (
      tester,
    ) async {
      TextStyle? style;
      await tester.pumpWidget(
        host(
          FossCard(
            description: Builder(
              builder: (context) {
                style = DefaultTextStyle.of(context).style;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(style?.color, FossThemeData.light.colors.mutedForeground);
      expect(style?.fontSize, 14);
    });

    testWidgets('content and footer inherit the card foreground', (
      tester,
    ) async {
      Color? contentColor;
      Color? footerColor;
      await tester.pumpWidget(
        host(
          FossCard(
            content: Builder(
              builder: (context) {
                contentColor = DefaultTextStyle.of(context).style.color;
                return const SizedBox();
              },
            ),
            footer: Builder(
              builder: (context) {
                footerColor = DefaultTextStyle.of(context).style.color;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      final fg = FossThemeData.light.colors.cardForeground;
      expect(contentColor, fg);
      expect(footerColor, fg);
    });
  });

  testWidgets('a header and footer with no content keep the full inset', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const FossCard(title: Text('Project'), footer: Text('footer')),
      ),
    );

    expect(slotPadding(tester, 'Project'), const EdgeInsets.all(24));
    expect(slotPadding(tester, 'footer'), const EdgeInsets.all(24));
  });

  testWidgets('a control in the action slot stays tappable', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      host(
        FossCard(
          title: const Text('Project'),
          action: FossButton(
            onPressed: () => tapped = true,
            child: const Text('Add'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add'));
    expect(tapped, isTrue);
  });
}
