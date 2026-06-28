import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

import 'host.dart';

Finder _circleOf(String label) => find.descendant(
  of: find.widgetWithText(FossRadio<String>, label),
  matching: find.byType(DecoratedBox),
);

ShapeDecoration _circle(WidgetTester tester, String label) =>
    tester.widget<DecoratedBox>(_circleOf(label).first).decoration
        as ShapeDecoration;

Widget _group({
  String? groupValue,
  ValueChanged<String?>? onChanged,
  String? label,
  String? errorText,
  bool enabled = true,
  List<Widget> children = const [
    FossRadio(value: 'a', label: 'Apple'),
    FossRadio(value: 'b', label: 'Banana'),
  ],
}) => host(
  FossRadioGroup<String>(
    groupValue: groupValue,
    onChanged: onChanged,
    label: label,
    errorText: errorText,
    enabled: enabled,
    children: children,
  ),
);

void main() {
  group('FossRadio selection', () {
    testWidgets('fires onChanged with the tapped value', (tester) async {
      String? picked;
      await tester.pumpWidget(_group(onChanged: (v) => picked = v));

      await tester.tap(find.text('Banana'));

      expect(picked, 'b');
    });

    testWidgets('checked circle fills primary and shows a dot', (tester) async {
      await tester.pumpWidget(_group(groupValue: 'a', onChanged: (_) {}));

      expect(
        _circle(tester, 'Apple').color,
        FossThemeData.light.colors.primary,
      );
      // The checked option adds the dot as a second decorated circle.
      expect(_circleOf('Apple'), findsNWidgets(2));
      expect(_circleOf('Banana'), findsOneWidget);
    });

    testWidgets('unchecked circle uses the input border on the surface', (
      tester,
    ) async {
      await tester.pumpWidget(_group(groupValue: 'a', onChanged: (_) {}));

      final decoration = _circle(tester, 'Banana');
      expect(decoration.color, FossThemeData.light.colors.background);
      expect(
        (decoration.shape as CircleBorder).side.color,
        FossThemeData.light.colors.input,
      );
    });

    testWidgets('checked circle drops its border', (tester) async {
      await tester.pumpWidget(_group(groupValue: 'a', onChanged: (_) {}));

      final shape = _circle(tester, 'Apple').shape as CircleBorder;
      expect(shape.side.style, BorderStyle.none);
    });
  });

  group('FossRadio disabled', () {
    testWidgets('disabling the group blocks every tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _group(enabled: false, onChanged: (_) => taps++),
      );

      await tester.tap(find.text('Apple'), warnIfMissed: false);

      expect(taps, 0);
    });

    testWidgets('a disabled option blocks only itself', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _group(
          onChanged: (v) => picked = v,
          children: const [
            FossRadio(value: 'a', label: 'Apple', enabled: false),
            FossRadio(value: 'b', label: 'Banana'),
          ],
        ),
      );

      await tester.tap(find.text('Apple'), warnIfMissed: false);
      expect(picked, isNull);

      await tester.tap(find.text('Banana'));
      expect(picked, 'b');
    });
  });

  group('FossRadioGroup captions', () {
    testWidgets('renders the label above the options', (tester) async {
      await tester.pumpWidget(_group(label: 'Fruit', onChanged: (_) {}));

      expect(find.text('Fruit'), findsOneWidget);
    });

    testWidgets('errorText shows the caption and deepens the border', (
      tester,
    ) async {
      await tester.pumpWidget(
        _group(errorText: 'Required', onChanged: (_) {}),
      );

      expect(find.text('Required'), findsOneWidget);
      final shape = _circle(tester, 'Apple').shape as CircleBorder;
      expect(
        shape.side.color,
        FossThemeData.light.colors.destructive.withValues(alpha: 0.36),
      );
    });
  });

  group('FossRadio card variant', () {
    ShapeDecoration card(WidgetTester tester, String label) =>
        tester.widget<DecoratedBox>(_circleOf(label).first).decoration
            as ShapeDecoration;

    testWidgets('checked card lifts its border and fill', (tester) async {
      await tester.pumpWidget(
        host(
          FossRadioGroup<String>(
            variant: FossRadioGroupVariant.card,
            groupValue: 'a',
            onChanged: (_) {},
            children: const [
              FossRadio(value: 'a', label: 'Apple'),
              FossRadio(value: 'b', label: 'Banana'),
            ],
          ),
        ),
      );

      final colors = FossThemeData.light.colors;
      final checked = card(tester, 'Apple');
      expect(
        checked.color,
        colors.accent.withValues(alpha: colors.accent.a * 0.5),
      );
      expect(
        (checked.shape as RoundedSuperellipseBorder).side.color,
        colors.primary.withValues(alpha: 0.48),
      );

      final rest = card(tester, 'Banana');
      expect(rest.color, isNull);
      expect(
        (rest.shape as RoundedSuperellipseBorder).side.color,
        colors.border,
      );
    });
  });

  group('FossRadio structure', () {
    testWidgets('renders a bare circle without text', (tester) async {
      await tester.pumpWidget(
        host(
          FossRadioGroup<String>(
            onChanged: (_) {},
            children: const [FossRadio(value: 'a')],
          ),
        ),
      );

      expect(find.byType(FossRadio<String>), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
    });

    testWidgets('used outside a group throws', (tester) async {
      await tester.pumpWidget(host(const FossRadio<String>(value: 'a')));

      expect(tester.takeException(), isA<FlutterError>());
    });

    testWidgets('dark lifts the unchecked fill off the surface', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossTheme(
            data: FossThemeData.dark,
            child: FossRadioGroup<String>(
              onChanged: (_) {},
              children: const [FossRadio(value: 'a', label: 'Apple')],
            ),
          ),
        ),
      );

      expect(
        _circle(tester, 'Apple').color,
        isNot(FossThemeData.dark.colors.background),
      );
    });
  });

  group('FossRadio accessibility', () {
    testWidgets('exposes the radio role and checked state', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_group(groupValue: 'a', onChanged: (_) {}));

      expect(
        tester.getSemantics(find.byType(FossRadio<String>).first),
        matchesSemantics(
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          label: 'Apple',
        ),
      );
      handle.dispose();
    });

    testWidgets('meets the minimum tap target', (tester) async {
      await tester.pumpWidget(
        host(
          FossRadioGroup<String>(
            onChanged: (_) {},
            children: const [FossRadio(value: 'a', label: 'Apple')],
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });
}
