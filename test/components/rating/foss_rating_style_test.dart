import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

void main() {
  group('FossRatingStyle.merge', () {
    test('returns this when other is null', () {
      const base = FossRatingStyle(glyphSize: 20, gap: 4);
      expect(base.merge(null), same(base));
    });

    test('other overrides matching fields', () {
      const base = FossRatingStyle(glyphSize: 20, gap: 4);
      const override = FossRatingStyle(glyphSize: 28);
      final merged = base.merge(override);
      expect(merged.glyphSize, 28);
      expect(merged.gap, 4);
    });

    test('null fields on other inherit from this', () {
      const base = FossRatingStyle(
        filledColor: Color(0xFF111111),
        glyphSize: 20,
      );
      const override = FossRatingStyle(glyphSize: 24);
      final merged = base.merge(override);
      expect(merged.filledColor, const Color(0xFF111111));
      expect(merged.glyphSize, 24);
    });

    test('merges colors field by field', () {
      const base = FossRatingStyle(
        filledColor: Color(0xFF000001),
        emptyColor: Color(0xFF000002),
      );
      const override = FossRatingStyle(emptyColor: Color(0xFF000003));
      final merged = base.merge(override);
      expect(merged.filledColor, const Color(0xFF000001));
      expect(merged.emptyColor, const Color(0xFF000003));
    });

    test('merging two empty styles leaves every field null', () {
      const merged = FossRatingStyle();
      final result = merged.merge(const FossRatingStyle());
      expect(result.filledColor, isNull);
      expect(result.emptyColor, isNull);
      expect(result.glyphSize, isNull);
      expect(result.gap, isNull);
    });
  });
}
