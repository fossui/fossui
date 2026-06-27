import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

void main() {
  test('standard durations', () {
    expect(FossMotion.standard.skeleton, const Duration(seconds: 2));
    expect(FossMotion.standard.caretBlink, const Duration(seconds: 1));
    expect(FossMotion.standard.spinner, const Duration(milliseconds: 1000));
  });

  test('copyWith overrides one duration', () {
    final m = FossMotion.standard.copyWith(
      skeleton: const Duration(seconds: 3),
    );
    expect(m.skeleton, const Duration(seconds: 3));
    expect(m.caretBlink, FossMotion.standard.caretBlink);
  });

  test('lerp snaps durations at the midpoint, it does not ease', () {
    const a = FossMotion.standard;
    const b = FossMotion(
      skeleton: Duration(seconds: 4),
      caretBlink: Duration(seconds: 1),
      spinner: Duration(milliseconds: 1000),
    );
    expect(a.lerp(b, 0.4).skeleton, a.skeleton); // before midpoint -> a
    expect(a.lerp(b, 0.6).skeleton, b.skeleton); // after midpoint -> b
  });
}
