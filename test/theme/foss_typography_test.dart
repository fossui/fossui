import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

void main() {
  const t = FossTypography.standard;
  final styles = [t.xs, t.sm, t.base, t.lg, t.xl, t.xl2];

  test('every style uses the Geist family', () {
    for (final s in styles) {
      expect(s.fontFamily, 'Geist');
    }
  });

  test('sizes follow the scale', () {
    expect(
      styles.map((s) => s.fontSize).toList(),
      [12, 14, 16, 18, 20, 24],
    );
  });

  test('line heights are the spec ratios', () {
    expect(t.xs.height, 14 / 12);
    expect(t.sm.height, 20 / 14);
    expect(t.xl2.height, 32 / 24);
  });

  test('letter spacing applied only where the scale specifies it', () {
    expect(t.xs.letterSpacing, 0.12);
    expect(t.lg.letterSpacing, -0.18);
    expect(t.xl2.letterSpacing, -0.36);
    expect(t.sm.letterSpacing, isNull);
  });

  test('copyWith overrides one style', () {
    final big = t.copyWith(sm: const TextStyle(fontSize: 99));
    expect(big.sm.fontSize, 99);
    expect(big.base, t.base);
  });

  test('weight getters set the weight and keep the rest', () {
    expect(t.sm.medium.fontWeight, FontWeight.w500);
    expect(t.sm.semibold.fontWeight, FontWeight.w600);
    expect(t.sm.bold.fontWeight, FontWeight.w700);
    expect(t.sm.medium.fontSize, t.sm.fontSize);
  });
}
