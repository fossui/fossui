import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

void main() {
  test('standard scale holds the documented px values', () {
    const r = FossRadii.standard;
    expect((r.sm, r.md, r.lg, r.xl, r.xl2), (4.0, 6.0, 8.0, 12.0, 16.0));
    expect(FossRadii.full, 9999.0);
  });

  test('lerp interpolates each step', () {
    final doubled = FossRadii.standard.copyWith(sm: 8);
    final mid = FossRadii.standard.lerp(doubled, 0.5);
    expect(mid.sm, 6); // halfway 4 -> 8
    expect(mid.md, 6); // unchanged
  });

  test('copyWith overrides one step', () {
    final r = FossRadii.standard.copyWith(lg: 10);
    expect(r.lg, 10);
    expect(r.md, FossRadii.standard.md);
  });
}
