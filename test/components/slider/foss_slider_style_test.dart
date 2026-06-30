import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

void main() {
  group('FossSliderStyle.merge', () {
    test('returns this when other is null', () {
      const base = FossSliderStyle(trackHeight: 4, thumbSize: 20);
      expect(base.merge(null), same(base));
    });

    test('other overrides matching fields', () {
      const base = FossSliderStyle(trackHeight: 4, thumbSize: 20);
      const override = FossSliderStyle(thumbSize: 24);
      final merged = base.merge(override);
      expect(merged.trackHeight, 4);
      expect(merged.thumbSize, 24);
    });

    test('null fields on other inherit from this', () {
      const base = FossSliderStyle(
        rangeColor: Color(0xFF111111),
        trackHeight: 4,
      );
      const override = FossSliderStyle(trackHeight: 6);
      final merged = base.merge(override);
      expect(merged.rangeColor, const Color(0xFF111111));
      expect(merged.trackHeight, 6);
    });

    test('merges colors field by field', () {
      const base = FossSliderStyle(
        trackColor: Color(0xFF000001),
        rangeColor: Color(0xFF000002),
      );
      const override = FossSliderStyle(rangeColor: Color(0xFF000003));
      final merged = base.merge(override);
      expect(merged.trackColor, const Color(0xFF000001));
      expect(merged.rangeColor, const Color(0xFF000003));
    });
  });
}
