import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

void main() {
  group('FossPaginationStyle.merge', () {
    test('null other returns this', () {
      // Non-const so the constructor runs at runtime.
      final base = FossPaginationStyle(gap: 2);
      expect(identical(base.merge(null), base), isTrue);
    });

    test('other overrides set fields, keeps the rest', () {
      const base = FossPaginationStyle(
        gap: 2,
        buttonSize: FossButtonSize.sm,
        activeVariant: FossButtonVariant.primary,
      );
      const override = FossPaginationStyle(
        gap: 6,
        inactiveVariant: FossButtonVariant.outline,
        ellipsisColor: Color(0xFF0000FF),
        ellipsisWidth: 28,
      );

      final merged = base.merge(override);
      expect(merged.gap, 6);
      expect(merged.buttonSize, FossButtonSize.sm);
      expect(merged.activeVariant, FossButtonVariant.primary);
      expect(merged.inactiveVariant, FossButtonVariant.outline);
      expect(merged.ellipsisColor, const Color(0xFF0000FF));
      expect(merged.ellipsisWidth, 28);
    });
  });

  group('style overrides reach the row', () {
    testWidgets('the variants swap', (tester) async {
      await tester.pumpWidget(
        host(
          FossPagination(
            page: 5,
            pageCount: 10,
            onPageChanged: (_) {},
            style: const FossPaginationStyle(
              activeVariant: FossButtonVariant.primary,
              inactiveVariant: FossButtonVariant.secondary,
              buttonSize: FossButtonSize.sm,
            ),
          ),
        ),
      );

      Finder control(String label) => find.byWidgetPredicate(
        (w) => w is FossButton && w.semanticLabel == label,
      );

      final current = tester.widget<FossButton>(control('Page 5'));
      final other = tester.widget<FossButton>(control('Page 6'));
      expect(current.variant, FossButtonVariant.primary);
      expect(other.variant, FossButtonVariant.secondary);
      expect(current.size, FossButtonSize.sm);
    });

    testWidgets('a narrowed ellipsis is honoured', (tester) async {
      await tester.pumpWidget(
        host(
          FossPagination(
            page: 5,
            pageCount: 10,
            onPageChanged: (_) {},
            style: const FossPaginationStyle(ellipsisWidth: 28),
          ),
        ),
      );

      final ellipsis = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'More pages',
      );
      expect(tester.getSize(ellipsis.first).width, 28);
    });
  });
}
