import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

void main() {
  test('standard scale holds the documented px values', () {
    const r = FossRadii.standard;
    expect((r.sm, r.md, r.lg, r.xl, r.xl2), (6.0, 8.0, 10.0, 14.0, 16.0));
    expect(FossRadii.full, 9999.0);
  });

  test('lerp interpolates each step', () {
    final doubled = FossRadii.standard.copyWith(sm: 10);
    final mid = FossRadii.standard.lerp(doubled, 0.5);
    expect(mid.sm, 8); // halfway 6 -> 10
    expect(mid.md, 8); // unchanged
  });

  test('copyWith overrides one step', () {
    final r = FossRadii.standard.copyWith(lg: 20);
    expect(r.lg, 20);
    expect(r.md, FossRadii.standard.md);
  });
}
