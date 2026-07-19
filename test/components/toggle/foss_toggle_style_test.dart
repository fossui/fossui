import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

void main() {
  group('FossToggleStyle.merge', () {
    test('null other returns this', () {
      const base = FossToggleStyle(borderRadius: 10, minHeight: 36);
      expect(identical(base.merge(null), base), isTrue);
    });

    test('other overrides set fields, keeps the rest', () {
      const base = FossToggleStyle(borderRadius: 10, minHeight: 36, gap: 6);
      const override = FossToggleStyle(minHeight: 32);

      final merged = base.merge(override);
      expect(merged.minHeight, 32);
      expect(merged.borderRadius, 10);
      expect(merged.gap, 6);
    });

    test('cornerRadius merges independently of borderRadius', () {
      const base = FossToggleStyle(borderRadius: 10);
      const override = FossToggleStyle(
        cornerRadius: BorderRadius.only(topLeft: Radius.circular(10)),
      );

      final merged = base.merge(override);
      expect(merged.borderRadius, 10);
      expect(merged.cornerRadius, isNotNull);
    });
  });
}
