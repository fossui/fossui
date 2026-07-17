import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

void main() {
  group('FossNumberFieldStyle.merge', () {
    test('returns this when other is null', () {
      const base = FossNumberFieldStyle(borderRadius: 8);
      expect(identical(base.merge(null), base), isTrue);
    });

    test('lays every non-null field of other over this', () {
      const base = FossNumberFieldStyle(borderRadius: 8, minHeight: 34);
      const override = FossNumberFieldStyle(minHeight: 30);

      final merged = base.merge(override);

      expect(merged.borderRadius, 8);
      expect(merged.minHeight, 30);
    });

    test('keeps a field when other leaves it null', () {
      const base = FossNumberFieldStyle(stepperHoverColor: Color(0xFF111111));
      const override = FossNumberFieldStyle(borderColor: Color(0xFF222222));

      final merged = base.merge(override);

      expect(merged.stepperHoverColor, const Color(0xFF111111));
      expect(merged.borderColor, const Color(0xFF222222));
    });
  });
}
