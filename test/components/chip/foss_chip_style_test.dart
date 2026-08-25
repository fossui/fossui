import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

ShapeDecoration _pill(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .map((b) => b.decoration)
    .whereType<ShapeDecoration>()
    .firstWhere((d) => d.shape is RoundedSuperellipseBorder);

void main() {
  group('FossChipStyle.merge', () {
    test('a null override returns the receiver', () {
      const base = FossChipStyle(borderRadius: 8, minHeight: 32);
      expect(base.merge(null), same(base));
    });

    test('non-null fields of the override win, the rest are kept', () {
      const base = FossChipStyle(borderRadius: 8, minHeight: 32, gap: 4);
      const override = FossChipStyle(minHeight: 24, gap: 6);

      final merged = base.merge(override);
      expect(merged.borderRadius, 8);
      expect(merged.minHeight, 24);
      expect(merged.gap, 6);
    });

    test('every field carries across', () {
      const override = FossChipStyle(
        side: BorderSide(color: Color(0xFF00FF00)),
        borderRadius: 2,
        padding: 12,
        minHeight: 40,
        textStyle: TextStyle(fontSize: 18),
        iconSize: 20,
        gap: 7,
        disabledOpacity: 0.3,
      );

      final merged = const FossChipStyle().merge(override);
      expect(merged.side, override.side);
      expect(merged.borderRadius, 2);
      expect(merged.padding, 12);
      expect(merged.minHeight, 40);
      expect(merged.textStyle, override.textStyle);
      expect(merged.iconSize, 20);
      expect(merged.gap, 7);
      expect(merged.disabledOpacity, 0.3);
    });
  });

  group('FossChip style override', () {
    testWidgets('the widget style beats the theme-resolved default', (
      tester,
    ) async {
      const brand = Color(0xFF16A34A);
      await tester.pumpWidget(
        host(
          const FossChip(
            label: Text('Design'),
            style: FossChipStyle(
              backgroundColor: WidgetStatePropertyAll(brand),
              borderRadius: 2,
              minHeight: 40,
            ),
          ),
        ),
      );

      final pill = _pill(tester);
      expect(pill.color, brand);
      expect(
        (pill.shape as RoundedSuperellipseBorder).borderRadius,
        const BorderRadius.all(Radius.circular(2)),
      );
      expect(tester.getSize(find.byType(FossChip)).height, 40);
    });

    testWidgets('a side override applies in every state', (tester) async {
      const edge = BorderSide(color: Color(0xFF0000FF));
      await tester.pumpWidget(
        host(
          FossChip(
            label: const Text('Design'),
            selected: true,
            onSelected: (_) {},
            style: const FossChipStyle(side: edge),
          ),
        ),
      );

      expect((_pill(tester).shape as RoundedSuperellipseBorder).side, edge);
    });

    testWidgets('foregroundColor drives the label', (tester) async {
      const ink = Color(0xFFFF00FF);
      await tester.pumpWidget(
        host(
          const FossChip(
            label: Text('Design'),
            style: FossChipStyle(
              foregroundColor: WidgetStatePropertyAll(ink),
            ),
          ),
        ),
      );

      final style = tester
          .widget<DefaultTextStyle>(
            find
                .ancestor(
                  of: find.text('Design'),
                  matching: find.byType(DefaultTextStyle),
                )
                .first,
          )
          .style;
      expect(style.color, ink);
    });
  });
}
