import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

void main() {
  group('FossThemeData', () {
    test('light and dark share every bundle but colors', () {
      const l = FossThemeData.light;
      const d = FossThemeData.dark;
      expect(d.colors, FossColors.dark);
      expect(d.radii, l.radii);
      expect(d.spacing, l.spacing);
      expect(d.typography, l.typography);
      expect(d.shadows, l.shadows);
      expect(d.motion, l.motion);
    });

    test('lerp hits the endpoints and eases between', () {
      const l = FossThemeData.light;
      final tighter = l.copyWith(radii: l.radii.copyWith(md: 2));
      expect(l.lerp(tighter, 0), l);
      expect(l.lerp(tighter, 1), tighter);
      expect(l.lerp(tighter, 0.5).radii.md, 4); // 6 -> 2 halfway
    });

    test('equality is value-based', () {
      expect(FossThemeData.light, FossThemeData.light);
      expect(FossThemeData.light == FossThemeData.dark, isFalse);
    });

    test('equal themes share a hashCode', () {
      expect(FossThemeData.light.hashCode, FossThemeData.light.hashCode);
      expect(
        FossThemeData.light.hashCode == FossThemeData.dark.hashCode,
        isFalse,
      );
    });

    test('copyWith with no arguments keeps every bundle', () {
      expect(FossThemeData.dark.copyWith(), FossThemeData.dark);
    });

    test('toThemeData registers the theme as an extension', () {
      final theme = FossThemeData.dark.toThemeData();
      expect(theme.extension<FossThemeData>(), FossThemeData.dark);
    });
  });

  group('context.fossTheme resolves the active theme', () {
    const dark = FossThemeData.dark;
    final darkBg = dark.colors.background;

    testWidgets('under MaterialApp via ThemeData.extensions', (tester) async {
      late FossThemeData resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [dark]),
          home: Builder(
            builder: (context) {
              resolved = context.fossTheme;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(resolved.colors.background, darkBg);
    });

    testWidgets('under CupertinoApp via FossTheme', (tester) async {
      late FossThemeData resolved;
      await tester.pumpWidget(
        CupertinoApp(
          home: FossTheme(
            data: dark,
            child: Builder(
              builder: (context) {
                resolved = context.fossTheme;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(resolved.colors.background, darkBg);
    });

    testWidgets('under bare WidgetsApp falls back to light', (tester) async {
      late FossThemeData resolved;
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, child) {
            resolved = context.fossTheme;
            return const SizedBox();
          },
        ),
      );
      expect(resolved.colors.background, FossThemeData.light.colors.background);
    });

    testWidgets('FossTheme notifies dependents when its data changes', (
      tester,
    ) async {
      final seen = <Color>[];
      Widget build(FossThemeData data) => FossTheme(
        data: data,
        child: Builder(
          builder: (context) {
            seen.add(context.fossTheme.colors.background);
            return const SizedBox();
          },
        ),
      );
      await tester.pumpWidget(build(FossThemeData.light));
      await tester.pumpWidget(build(FossThemeData.dark));
      expect(seen, [
        FossThemeData.light.colors.background,
        FossThemeData.dark.colors.background,
      ]);
    });

    testWidgets('FossTheme wins over a registered extension', (tester) async {
      late FossThemeData resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [FossThemeData.dark]),
          home: FossTheme(
            data: FossThemeData.light,
            child: Builder(
              builder: (context) {
                resolved = context.fossTheme;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(resolved.colors.background, FossThemeData.light.colors.background);
    });
  });
}
