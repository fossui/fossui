import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

void main() {
  group('FossThemeData.retheme', () {
    test('an unset field keeps the base value', () {
      const brand = Color(0xFF51F0A8);
      final theme = FossThemeData.light.retheme(
        const FossThemeSpec(primary: brand),
      );
      expect(theme.colors.primary, brand);
      expect(theme.colors.secondary, FossColors.light.secondary);
      expect(theme.radii, FossThemeData.light.radii);
      expect(theme.spacing, FossThemeData.light.spacing);
      expect(theme.typography, FossThemeData.light.typography);
    });

    test('empty spec round-trips to the light base', () {
      expect(
        FossThemeData.light.retheme(const FossThemeSpec()),
        FossThemeData.light,
      );
    });

    test('a runtime-built spec forwards its field', () {
      // Non-const construction so the const constructor runs at runtime.
      final base = FossThemeData.light.colors;
      final spec = FossThemeSpec(primary: base.secondary);
      expect(FossThemeData.light.retheme(spec).colors.primary, base.secondary);
    });

    test('base swap starts from the dark set', () {
      final theme = FossThemeData.dark.retheme(
        const FossThemeSpec(primary: Color(0xFF51F0A8)),
      );
      expect(theme.colors.background, FossColors.dark.background);
      expect(theme.colors.secondary, FossColors.dark.secondary);
    });

    test('every color role forwards independently', () {
      // Distinct value per role: proves the spec covers the full set and each
      // maps to its own field with no cross-talk.
      const spec = FossThemeSpec(
        background: Color(0xFF000001),
        foreground: Color(0xFF000002),
        card: Color(0xFF000003),
        cardForeground: Color(0xFF000004),
        popover: Color(0xFF000005),
        popoverForeground: Color(0xFF000006),
        primary: Color(0xFF000007),
        primaryForeground: Color(0xFF000008),
        secondary: Color(0xFF000009),
        secondaryForeground: Color(0xFF00000A),
        muted: Color(0xFF00000B),
        mutedForeground: Color(0xFF00000C),
        accent: Color(0xFF00000D),
        accentForeground: Color(0xFF00000E),
        destructive: Color(0xFF00000F),
        destructiveForeground: Color(0xFF000010),
        destructiveForegroundOn: Color(0xFF000011),
        info: Color(0xFF000012),
        infoForeground: Color(0xFF000013),
        success: Color(0xFF000014),
        successForeground: Color(0xFF000015),
        warning: Color(0xFF000016),
        warningForeground: Color(0xFF000017),
        border: Color(0xFF000018),
        input: Color(0xFF000019),
        ring: Color(0xFF00001A),
      );
      final c = FossThemeData.light.retheme(spec).colors;
      expect(c.background, const Color(0xFF000001));
      expect(c.foreground, const Color(0xFF000002));
      expect(c.card, const Color(0xFF000003));
      expect(c.cardForeground, const Color(0xFF000004));
      expect(c.popover, const Color(0xFF000005));
      expect(c.popoverForeground, const Color(0xFF000006));
      expect(c.primary, const Color(0xFF000007));
      expect(c.primaryForeground, const Color(0xFF000008));
      expect(c.secondary, const Color(0xFF000009));
      expect(c.secondaryForeground, const Color(0xFF00000A));
      expect(c.muted, const Color(0xFF00000B));
      expect(c.mutedForeground, const Color(0xFF00000C));
      expect(c.accent, const Color(0xFF00000D));
      expect(c.accentForeground, const Color(0xFF00000E));
      expect(c.destructive, const Color(0xFF00000F));
      expect(c.destructiveForeground, const Color(0xFF000010));
      expect(c.destructiveForegroundOn, const Color(0xFF000011));
      expect(c.info, const Color(0xFF000012));
      expect(c.infoForeground, const Color(0xFF000013));
      expect(c.success, const Color(0xFF000014));
      expect(c.successForeground, const Color(0xFF000015));
      expect(c.warning, const Color(0xFF000016));
      expect(c.warningForeground, const Color(0xFF000017));
      expect(c.border, const Color(0xFF000018));
      expect(c.input, const Color(0xFF000019));
      expect(c.ring, const Color(0xFF00001A));
    });

    test('radius seed derives the full scale', () {
      final theme = FossThemeData.light.retheme(
        const FossThemeSpec(radius: 10),
      );
      expect(theme.radii, FossRadii.standard);
    });

    test('spacing seed maps straight to the unit', () {
      final theme = FossThemeData.light.retheme(
        const FossThemeSpec(spacing: 4.3),
      );
      expect(theme.spacing, const FossSpacing(unit: 4.3));
    });

    test('shadow color re-tints every layer, keeping alpha and geometry', () {
      const tint = Color(0xFF3366FF);
      final theme = FossThemeData.light.retheme(
        const FossThemeSpec(shadowColor: tint),
      );
      const base = FossShadows.standard;
      for (final step in [
        (theme.shadows.xs, base.xs),
        (theme.shadows.sm, base.sm),
        (theme.shadows.md, base.md),
        (theme.shadows.lg, base.lg),
      ]) {
        final (tinted, original) = step;
        expect(tinted.length, original.length);
        for (var i = 0; i < tinted.length; i++) {
          expect(tinted[i].color.r, tint.r);
          expect(tinted[i].color.g, tint.g);
          expect(tinted[i].color.b, tint.b);
          expect(tinted[i].color.a, original[i].color.a);
          expect(tinted[i].offset, original[i].offset);
          expect(tinted[i].blurRadius, original[i].blurRadius);
          expect(tinted[i].spreadRadius, original[i].spreadRadius);
        }
      }
    });

    test('font family re-families every step, keeping metrics', () {
      const family = 'Plus Jakarta Sans';
      final t = FossThemeData.light
          .retheme(const FossThemeSpec(fontFamily: family))
          .typography;
      const base = FossTypography.standard;
      for (final step in [
        (t.xs, base.xs),
        (t.sm, base.sm),
        (t.base, base.base),
        (t.lg, base.lg),
        (t.xl, base.xl),
        (t.xl2, base.xl2),
      ]) {
        final (styled, original) = step;
        expect(styled.fontFamily, family);
        expect(styled.fontSize, original.fontSize);
        expect(styled.height, original.height);
        expect(styled.letterSpacing, original.letterSpacing);
      }
    });
  });

  group('FossRadii.fromBase', () {
    test('base 10 reproduces the standard scale', () {
      expect(FossRadii.fromBase(10), FossRadii.standard);
    });

    test('offsets each step from the base', () {
      final r = FossRadii.fromBase(22);
      expect((r.sm, r.md, r.lg, r.xl, r.xl2), (18.0, 20.0, 22.0, 26.0, 28.0));
    });

    test('clamps negative steps at 0', () {
      final r = FossRadii.fromBase(2);
      expect((r.sm, r.md, r.lg, r.xl, r.xl2), (0.0, 0.0, 2.0, 6.0, 8.0));
    });
  });
}
