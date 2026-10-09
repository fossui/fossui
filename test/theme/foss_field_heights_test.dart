import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

void main() {
  test('standard scale holds the documented px values', () {
    const h = FossFieldHeights.standard;
    expect((h.sm, h.md, h.lg), (30.0, 34.0, 38.0));
  });

  test('lerp interpolates each step', () {
    final taller = FossFieldHeights.standard.copyWith(sm: 34);
    final mid = FossFieldHeights.standard.lerp(taller, 0.5);
    expect(mid.sm, 32); // halfway 30 -> 34
    expect(mid.md, 34); // unchanged
  });

  test('copyWith overrides one step', () {
    final h = FossFieldHeights.standard.copyWith(lg: 48);
    expect(h.lg, 48);
    expect(h.md, FossFieldHeights.standard.md);
  });

  group('FossFieldHeights.fromBase', () {
    test('base 34 reproduces the standard scale', () {
      expect(FossFieldHeights.fromBase(34), FossFieldHeights.standard);
    });

    test('offsets each step from the base', () {
      final h = FossFieldHeights.fromBase(40);
      expect((h.sm, h.md, h.lg), (36.0, 40.0, 44.0));
    });

    test('clamps negative steps at 0', () {
      final h = FossFieldHeights.fromBase(2);
      expect((h.sm, h.md, h.lg), (0.0, 2.0, 6.0));
    });

    test('the control-height seed derives the field scale offset by 2', () {
      final theme = FossThemeData.light.retheme(
        const FossThemeSpec(controlHeight: 40),
      );
      // Fields sit one step shorter, so a seed of 40 derives fields from 38.
      expect(theme.fieldHeights, FossFieldHeights.fromBase(38));
      expect(theme.fieldHeights, isNot(FossFieldHeights.standard));
    });
  });
}
