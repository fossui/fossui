import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

void main() {
  group('FossCheckboxStyle.merge', () {
    test('returns this when other is null', () {
      const base = FossCheckboxStyle(boxSize: 18, glyphSize: 14);
      expect(base.merge(null), same(base));
    });

    test('other overrides matching fields', () {
      const base = FossCheckboxStyle(boxSize: 18, glyphSize: 14);
      const override = FossCheckboxStyle(glyphSize: 16);
      final merged = base.merge(override);
      expect(merged.boxSize, 18);
      expect(merged.glyphSize, 16);
    });

    test('null fields on other inherit from this', () {
      const base = FossCheckboxStyle(
        checkedColor: Color(0xFF111111),
        gap: 8,
      );
      const override = FossCheckboxStyle(gap: 12);
      final merged = base.merge(override);
      expect(merged.checkedColor, const Color(0xFF111111));
      expect(merged.gap, 12);
    });

    test('merges colors field by field', () {
      const base = FossCheckboxStyle(
        backgroundColor: Color(0xFF000001),
        checkColor: Color(0xFF000002),
      );
      const override = FossCheckboxStyle(checkColor: Color(0xFF000003));
      final merged = base.merge(override);
      expect(merged.backgroundColor, const Color(0xFF000001));
      expect(merged.checkColor, const Color(0xFF000003));
    });
  });
}
