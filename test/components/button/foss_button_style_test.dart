import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

void main() {
  group('FossButtonStyle.merge', () {
    test('lays each non-null field of the argument over the receiver', () {
      const base = FossButtonStyle(borderRadius: 8, gap: 4, minHeight: 36);
      const over = FossButtonStyle(borderRadius: 99);

      final merged = base.merge(over);

      expect(merged.borderRadius, 99, reason: 'overridden');
      expect(merged.gap, 4, reason: 'kept from base');
      expect(merged.minHeight, 36, reason: 'kept from base');
    });

    test('a null argument keeps the receiver unchanged', () {
      const base = FossButtonStyle(borderRadius: 8, gap: 4);

      final merged = base.merge(null);

      expect(merged.borderRadius, 8);
      expect(merged.gap, 4);
    });

    test('a null field on the argument does not erase the receiver', () {
      const base = FossButtonStyle(iconSize: 18);
      const over = FossButtonStyle(gap: 6);

      final merged = base.merge(over);

      expect(merged.iconSize, 18);
      expect(merged.gap, 6);
    });

    test('stateful fields override', () {
      const base = FossButtonStyle(
        foregroundColor: WidgetStatePropertyAll(Color(0xFF000000)),
      );
      const over = FossButtonStyle(
        foregroundColor: WidgetStatePropertyAll(Color(0xFFFFFFFF)),
      );

      final merged = base.merge(over);

      expect(
        merged.foregroundColor!.resolve(const {}),
        const Color(0xFFFFFFFF),
      );
    });
  });
}
