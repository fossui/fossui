import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

void main() {
  group('FossListTileStyle.merge', () {
    test('a null override returns the receiver', () {
      const base = FossListTileStyle(minHeight: 48, gap: 16);
      expect(base.merge(null), same(base));
    });

    test('non-null fields of the override win, the rest are kept', () {
      const base = FossListTileStyle(minHeight: 48, gap: 16, iconSize: 18);
      const override = FossListTileStyle(gap: 12);

      final merged = base.merge(override);
      expect(merged.minHeight, 48);
      expect(merged.gap, 12);
      expect(merged.iconSize, 18);
    });

    test('every field carries across', () {
      final override = FossListTileStyle(
        backgroundColor: WidgetStateProperty.all(const Color(0xFF00FF00)),
        padding: const EdgeInsets.all(8),
        gap: 4,
        minHeight: 64,
        borderRadius: 2,
        titleStyle: const TextStyle(fontSize: 22),
        subtitleStyle: const TextStyle(fontSize: 11),
        iconSize: 30,
      );

      final merged = const FossListTileStyle().merge(override);
      expect(
        merged.backgroundColor?.resolve(const {}),
        const Color(0xFF00FF00),
      );
      expect(merged.padding, const EdgeInsets.all(8));
      expect(merged.gap, 4);
      expect(merged.minHeight, 64);
      expect(merged.borderRadius, 2);
      expect(merged.titleStyle?.fontSize, 22);
      expect(merged.subtitleStyle?.fontSize, 11);
      expect(merged.iconSize, 30);
    });
  });
}
