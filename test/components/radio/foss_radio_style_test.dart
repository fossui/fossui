import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

void main() {
  group('FossRadioStyle.merge', () {
    test('returns this when other is null', () {
      const base = FossRadioStyle(circleSize: 18, dotSize: 8);
      expect(base.merge(null), same(base));
    });

    test('other overrides matching fields', () {
      const base = FossRadioStyle(circleSize: 18, dotSize: 8);
      const override = FossRadioStyle(dotSize: 10);
      final merged = base.merge(override);
      expect(merged.circleSize, 18);
      expect(merged.dotSize, 10);
    });

    test('null fields on other inherit from this', () {
      const base = FossRadioStyle(
        checkedColor: Color(0xFF111111),
        gap: 8,
      );
      const override = FossRadioStyle(gap: 12);
      final merged = base.merge(override);
      expect(merged.checkedColor, const Color(0xFF111111));
      expect(merged.gap, 12);
    });

    test('merges colors field by field', () {
      const base = FossRadioStyle(
        backgroundColor: Color(0xFF000001),
        dotColor: Color(0xFF000002),
      );
      const override = FossRadioStyle(dotColor: Color(0xFF000003));
      final merged = base.merge(override);
      expect(merged.backgroundColor, const Color(0xFF000001));
      expect(merged.dotColor, const Color(0xFF000003));
    });
  });
}
