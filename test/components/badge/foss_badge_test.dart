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

  ShapeDecoration pillDecoration(WidgetTester tester) {
    final box = find.descendant(
      of: find.byType(FossBadge),
      matching: find.byType(DecoratedBox),
    );
    return tester.widget<DecoratedBox>(box.first).decoration as ShapeDecoration;
  }

  RoundedSuperellipseBorder pillShape(WidgetTester tester) =>
      pillDecoration(tester).shape as RoundedSuperellipseBorder;

  TextStyle labelStyle(WidgetTester tester) {
    final styles = find.descendant(
      of: find.byType(FossBadge),
      matching: find.byType(DefaultTextStyle),
    );
    return tester.widget<DefaultTextStyle>(styles.first).style;
  }

  group('FossBadgeStyle.merge', () {
    test('lays every non-null field of other over this', () {
      const base = FossBadgeStyle(
        backgroundColor: Color(0xFF111111),
        borderColor: Color(0xFF222222),
        foregroundColor: Color(0xFF333333),
        borderRadius: 4,
        labelStyle: TextStyle(fontSize: 9),
      );
      const over = FossBadgeStyle(
        foregroundColor: Color(0xFF444444),
        borderRadius: 12,
      );

      final merged = base.merge(over);

      expect(merged.backgroundColor, const Color(0xFF111111));
      expect(merged.borderColor, const Color(0xFF222222));
      expect(merged.foregroundColor, const Color(0xFF444444));
      expect(merged.borderRadius, 12);
      expect(merged.labelStyle, const TextStyle(fontSize: 9));
    });

    test('null other returns this unchanged', () {
      const base = FossBadgeStyle(backgroundColor: Color(0xFF111111));
      expect(identical(base.merge(null), base), isTrue);
    });
  });

  group('variant colors', () {
    Future<void> pump(
      WidgetTester tester,
      FossBadgeVariant variant, {
      FossThemeData? theme,
    }) => tester.pumpWidget(
      host(
        FossBadge(label: const Text('x'), variant: variant),
        theme: theme,
      ),
    );

    testWidgets('primary fills primary with its foreground', (tester) async {
      const c = FossColors.light;
      await pump(tester, FossBadgeVariant.primary);
      expect(pillDecoration(tester).color, c.primary);
      expect(labelStyle(tester).color, c.primaryForeground);
    });

    testWidgets('secondary fills secondary', (tester) async {
      const c = FossColors.light;
      await pump(tester, FossBadgeVariant.secondary);
      expect(pillDecoration(tester).color, c.secondary);
      expect(labelStyle(tester).color, c.secondaryForeground);
    });

    testWidgets('outline is background with a border', (tester) async {
      const c = FossColors.light;
      await pump(tester, FossBadgeVariant.outline);
      expect(pillDecoration(tester).color, c.background);
      expect(pillShape(tester).side.color, c.border);
      expect(labelStyle(tester).color, c.foreground);
    });

    testWidgets('destructive is solid with the on-fill foreground', (
      tester,
    ) async {
      const c = FossColors.light;
      await pump(tester, FossBadgeVariant.destructive);
      expect(pillDecoration(tester).color, c.destructive);
      expect(labelStyle(tester).color, c.destructiveForegroundOn);
    });

    testWidgets('solid variants draw no border', (tester) async {
      await pump(tester, FossBadgeVariant.primary);
      expect(pillShape(tester).side, BorderSide.none);
    });

    testWidgets('soft info tints info at 8% in light', (tester) async {
      const c = FossColors.light;
      await pump(tester, FossBadgeVariant.info);
      expect(
        pillDecoration(tester).color,
        c.info.withValues(alpha: c.info.a * 0.08),
      );
      expect(labelStyle(tester).color, c.infoForeground);
    });

    testWidgets('soft info tints info at 16% in dark', (tester) async {
      const c = FossColors.dark;
      await pump(tester, FossBadgeVariant.info, theme: FossThemeData.dark);
      expect(
        pillDecoration(tester).color,
        c.info.withValues(alpha: c.info.a * 0.16),
      );
      expect(labelStyle(tester).color, c.infoForeground);
    });

    testWidgets('error tints destructive but uses its paired foreground', (
      tester,
    ) async {
      const c = FossColors.light;
      await pump(tester, FossBadgeVariant.error);
      expect(
        pillDecoration(tester).color,
        c.destructive.withValues(alpha: c.destructive.a * 0.08),
      );
      expect(labelStyle(tester).color, c.destructiveForeground);
    });

    testWidgets('success and warning tint their roles', (tester) async {
      const c = FossColors.light;
      await pump(tester, FossBadgeVariant.success);
      expect(
        pillDecoration(tester).color,
        c.success.withValues(alpha: c.success.a * 0.08),
      );
      await pump(tester, FossBadgeVariant.warning);
      expect(
        pillDecoration(tester).color,
        c.warning.withValues(alpha: c.warning.a * 0.08),
      );
    });
  });

  group('sizes', () {
    Future<void> pump(WidgetTester tester, FossBadgeSize size) =>
        tester.pumpWidget(
          host(FossBadge(label: const Text('x'), size: size)),
        );

    double minWidth(WidgetTester tester) => tester
        .widget<ConstrainedBox>(
          find.descendant(
            of: find.byType(FossBadge),
            matching: find.byType(ConstrainedBox),
          ),
        )
        .constraints
        .minWidth;

    double padding(WidgetTester tester) =>
        (tester
                    .widget<Padding>(
                      find.descendant(
                        of: find.byType(FossBadge),
                        matching: find.byType(Padding),
                      ),
                    )
                    .padding
                as EdgeInsets)
            .left;

    testWidgets('sm: height 20, padding 3, xs type, radius 4', (tester) async {
      await pump(tester, FossBadgeSize.sm);
      expect(minWidth(tester), 20);
      expect(padding(tester), 3);
      expect(labelStyle(tester).fontSize, FossTypography.standard.xs.fontSize);
      expect(
        pillShape(tester).borderRadius.resolve(TextDirection.ltr).topLeft.x,
        4,
      );
    });

    testWidgets('md: height 22, padding 3, sm type, radii.sm', (tester) async {
      await pump(tester, FossBadgeSize.md);
      expect(minWidth(tester), 22);
      expect(padding(tester), 3);
      expect(labelStyle(tester).fontSize, FossTypography.standard.sm.fontSize);
      expect(
        pillShape(tester).borderRadius.resolve(TextDirection.ltr).topLeft.x,
        FossRadii.standard.sm,
      );
    });

    testWidgets('lg: height 26, padding 5, base type, radii.sm', (
      tester,
    ) async {
      await pump(tester, FossBadgeSize.lg);
      expect(minWidth(tester), 26);
      expect(padding(tester), 5);
      expect(
        labelStyle(tester).fontSize,
        FossTypography.standard.base.fontSize,
      );
      expect(
        pillShape(tester).borderRadius.resolve(TextDirection.ltr).topLeft.x,
        FossRadii.standard.sm,
      );
    });
  });

  group('slots', () {
    testWidgets('renders leading, label, and trailing', (tester) async {
      await tester.pumpWidget(
        host(
          const FossBadge(
            label: Text('Tag'),
            leading: Text('L'),
            trailing: Text('T'),
          ),
        ),
      );
      expect(find.text('L'), findsOneWidget);
      expect(find.text('Tag'), findsOneWidget);
      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('label-only renders without icon slots', (tester) async {
      await tester.pumpWidget(host(const FossBadge(label: Text('Tag'))));
      expect(find.text('Tag'), findsOneWidget);
      expect(find.byType(IconTheme), findsNothing);
    });

    testWidgets('icon slots are sized to 14 and dimmed', (tester) async {
      await tester.pumpWidget(
        host(const FossBadge(label: Text('Tag'), leading: Text('L'))),
      );
      final iconTheme = tester.widget<IconTheme>(
        find.descendant(
          of: find.byType(FossBadge),
          matching: find.byType(IconTheme),
        ),
      );
      expect(iconTheme.data.size, 14);
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(FossBadge),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.8);
    });
  });

  group('accessibility', () {
    testWidgets('label reads in place without a semantics wrapper', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FossBadge(label: Text('New'))));
      expect(
        find.descendant(
          of: find.byType(FossBadge),
          matching: find.byType(ExcludeSemantics),
        ),
        findsNothing,
      );
    });

    testWidgets('semanticsLabel replaces the read-in-place content', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const FossBadge(label: Text('3'), semanticsLabel: '3 unread'),
        ),
      );
      expect(
        find.bySemanticsLabel('3 unread'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('style overrides win over the variant', (tester) async {
      await tester.pumpWidget(
        host(
          const FossBadge(
            label: Text('x'),
            style: FossBadgeStyle(
              backgroundColor: Color(0xFF010203),
              foregroundColor: Color(0xFF040506),
            ),
          ),
        ),
      );
      expect(pillDecoration(tester).color, const Color(0xFF010203));
      expect(labelStyle(tester).color, const Color(0xFF040506));
    });

    testWidgets('grows with textScale and mirrors under RTL', (tester) async {
      await tester.pumpWidget(
        host(
          const FossBadge(label: Text('Tag'), leading: Text('L')),
          direction: TextDirection.rtl,
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      final size = tester.getSize(find.byType(FossBadge));
      expect(size.height, greaterThan(22));
    });
  });
}
