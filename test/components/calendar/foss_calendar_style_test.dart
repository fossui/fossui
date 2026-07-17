import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

void main() {
  group('FossCalendarStyle.merge', () {
    test('returns this when other is null', () {
      const base = FossCalendarStyle(dayRadius: 10);
      expect(base.merge(null), same(base));
    });

    test('other non-null fields win, this fills the gaps', () {
      const base = FossCalendarStyle(dayRadius: 10, cellSize: 40);
      const override = FossCalendarStyle(dayRadius: 6);
      final merged = base.merge(override);
      expect(merged.dayRadius, 6);
      expect(merged.cellSize, 40);
    });

    test('null fields in other do not clear this', () {
      const base = FossCalendarStyle(selectedColor: Color(0xFF112233));
      const override = FossCalendarStyle(rangeColor: Color(0xFF445566));
      final merged = base.merge(override);
      expect(merged.selectedColor, const Color(0xFF112233));
      expect(merged.rangeColor, const Color(0xFF445566));
    });
  });

  group('FossDateRange', () {
    test('equality compares by calendar day, ignoring time', () {
      final a = FossDateRange(
        start: DateTime(2026, 3, 2, 9, 30),
        end: DateTime(2026, 3, 8, 23),
      );
      final b = FossDateRange(
        start: DateTime(2026, 3, 2),
        end: DateTime(2026, 3, 8),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differing days are unequal', () {
      final a = FossDateRange(
        start: DateTime(2026, 3, 2),
        end: DateTime(2026, 3, 8),
      );
      final b = FossDateRange(
        start: DateTime(2026, 3, 2),
        end: DateTime(2026, 3, 9),
      );
      expect(a, isNot(b));
    });
  });
}
