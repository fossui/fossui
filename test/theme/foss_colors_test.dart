import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

/// One sRGB channel of `a` blended over `b` at weight `pA` (0..1).
int mix(int a, int b, double pA) => (a * pA + b * (1 - pA)).round();

/// The alpha byte for a percent opacity.
int alpha(double pct) => (pct / 100 * 255).round();

void main() {
  group('FossColors baked alpha overlays', () {
    test('light: black overlays at the documented opacities', () {
      Color blackAt(double pct) => Color.fromARGB(alpha(pct), 0, 0, 0);

      expect(FossColors.light.secondary, blackAt(4));
      expect(FossColors.light.muted, blackAt(4));
      expect(FossColors.light.accent, blackAt(4));
      expect(FossColors.light.border, blackAt(8));
      expect(FossColors.light.input, blackAt(10));
    });

    test('dark: white overlays at the documented opacities', () {
      Color whiteAt(double pct) => Color.fromARGB(alpha(pct), 255, 255, 255);

      expect(FossColors.dark.secondary, whiteAt(4));
      expect(FossColors.dark.muted, whiteAt(4));
      expect(FossColors.dark.accent, whiteAt(4));
      expect(FossColors.dark.border, whiteAt(6));
      expect(FossColors.dark.input, whiteAt(8));
    });
  });

  group('FossColors baked blend values', () {
    // Gray blends: one channel suffices.
    Color gray(int v) => Color.fromARGB(255, v, v, v);

    test('dark neutral surfaces', () {
      // darkest neutral = 10, white = 255.
      expect(FossColors.dark.background, gray(mix(10, 255, 0.96))); // 20
      // card/popover blend over the resolved background (20).
      expect(FossColors.dark.card, gray(mix(20, 255, 0.98))); // 25
      expect(FossColors.dark.popover, gray(mix(20, 255, 0.96))); // 29
    });

    test('muted-foreground both themes', () {
      // mid neutral = 115.
      expect(FossColors.light.mutedForeground, gray(mix(115, 0, 0.9))); // 104
      expect(FossColors.dark.mutedForeground, gray(mix(115, 255, 0.9))); // 129
    });

    test('destructive dark is a per-channel blend over white', () {
      // red-500 = #FB2C36 -> (251, 44, 54), white channels = 255.
      final expected = Color.fromARGB(
        255,
        mix(251, 255, 0.9),
        mix(44, 255, 0.9),
        mix(54, 255, 0.9),
      );
      expect(FossColors.dark.destructive, expected);
    });
  });

  group('FossColors primitive-referenced roles', () {
    test('light roles resolve to the right swatches', () {
      expect(FossColors.light.foreground, const Color(0xFF262626));
      expect(FossColors.light.primaryForeground, const Color(0xFFFAFAFA));
      expect(FossColors.light.destructive, const Color(0xFFFB2C36));
      expect(FossColors.light.ring, const Color(0xFFA1A1A1));
    });
  });

  group('FossColors ThemeExtension behavior', () {
    test('lerp endpoints return the bounding instances', () {
      expect(FossColors.light.lerp(FossColors.dark, 0), FossColors.light);
      expect(FossColors.light.lerp(FossColors.dark, 1), FossColors.dark);
    });

    test('copyWith overrides one role and keeps the rest', () {
      const brand = Color(0xFF6D28D9);
      final updated = FossColors.light.copyWith(primary: brand);
      expect(updated.primary, brand);
      expect(updated.background, FossColors.light.background);
    });
  });

  group('FossColors.isDark', () {
    test('reads the background luminance', () {
      expect(FossColors.light.isDark, isFalse);
      expect(FossColors.dark.isDark, isTrue);
    });

    test('follows a retheme of the background', () {
      final lifted = FossColors.light.copyWith(
        background: const Color(0xFF000000),
      );
      expect(lifted.isDark, isTrue);
    });
  });
}
