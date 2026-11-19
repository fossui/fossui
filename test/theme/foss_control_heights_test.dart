import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

void main() {
  test('standard scale holds the documented px values', () {
    const h = FossControlHeights.standard;
    expect((h.sm, h.md, h.lg), (32.0, 36.0, 40.0));
  });

  test('lerp interpolates each step', () {
    final taller = FossControlHeights.standard.copyWith(sm: 36);
    final mid = FossControlHeights.standard.lerp(taller, 0.5);
    expect(mid.sm, 34); // halfway 32 -> 36
    expect(mid.md, 36); // unchanged
  });

  test('copyWith overrides one step', () {
    final h = FossControlHeights.standard.copyWith(lg: 48);
    expect(h.lg, 48);
    expect(h.md, FossControlHeights.standard.md);
  });

  group('FossControlHeights.fromBase', () {
    test('base 36 reproduces the standard scale', () {
      expect(FossControlHeights.fromBase(36), FossControlHeights.standard);
    });

    test('offsets each step from the base', () {
      final h = FossControlHeights.fromBase(44);
      expect((h.sm, h.md, h.lg), (40.0, 44.0, 48.0));
    });

    test('clamps negative steps at 0', () {
      final h = FossControlHeights.fromBase(2);
      expect((h.sm, h.md, h.lg), (0.0, 2.0, 6.0));
    });

    test('retheme with a custom seed drives a non-standard scale', () {
      final theme = FossThemeData.light.retheme(
        const FossThemeSpec(controlHeight: 44),
      );
      expect(theme.controlHeights, FossControlHeights.fromBase(44));
      expect(theme.controlHeights, isNot(FossControlHeights.standard));
    });
  });
}
