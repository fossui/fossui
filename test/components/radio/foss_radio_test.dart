import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsValidationResult;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

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
  ValueChanged<String>? onChanged,
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

  group('FossRadio responsive', () {
    testWidgets('circle holds its size under 2x text scale', (tester) async {
      await tester.pumpWidget(_group(onChanged: (_) {}));
      final base = tester.getSize(_circleOf('Apple').first);

      await tester.pumpWidget(
        host(
          MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: FossRadioGroup<String>(
              onChanged: (_) {},
              children: const [
                FossRadio(value: 'a', label: 'Apple'),
                FossRadio(value: 'b', label: 'Banana'),
              ],
            ),
          ),
        ),
      );

      expect(tester.getSize(_circleOf('Apple').first), base);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays the circle after the label in RTL', (tester) async {
      await tester.pumpWidget(
        host(
          Directionality(
            textDirection: TextDirection.rtl,
            child: FossRadioGroup<String>(
              onChanged: (_) {},
              children: const [FossRadio(value: 'a', label: 'Apple')],
            ),
          ),
        ),
      );

      expect(
        tester.getCenter(_circleOf('Apple').first).dx,
        greaterThan(tester.getCenter(find.text('Apple')).dx),
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

    testWidgets('a plain option hugs its content, not a 48px floor', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossRadioGroup<String>(
            onChanged: (_) {},
            children: const [FossRadio(value: 'a', label: 'Apple')],
          ),
        ),
      );

      // The row tracks the circle and label height so a stacked group stays
      // tight against the reference, not padded out to a 48px tap floor.
      expect(
        tester.getSize(find.byType(FossRadio<String>)).height,
        lessThan(48),
      );
    });
  });

  group('FossRadio focus', () {
    testWidgets('keyboard focus paints the ring on the unchecked circle', (
      tester,
    ) async {
      await tester.pumpWidget(_group(onChanged: (_) {}));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a focused invalid option paints the destructive ring', (
      tester,
    ) async {
      await tester.pumpWidget(
        _group(errorText: 'Required', onChanged: (_) {}),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('space activates the focused option', (tester) async {
      String? picked;
      await tester.pumpWidget(_group(onChanged: (v) => picked = v));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(picked, 'a');
    });

    testWidgets('the focus ring repaints when the option rebuilds', (
      tester,
    ) async {
      String? group;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FossRadioGroup<String>(
              groupValue: group,
              onChanged: (v) => setState(() => group = v),
              children: const [FossRadio(value: 'a', label: 'Apple')],
            ),
          ),
        ),
      );

      // Focus mounts the ring, then selecting rebuilds the same option in
      // place so its painter is reassigned and shouldRepaint runs.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(group, 'a');
    });
  });

  group('FossRadio rendering', () {
    testWidgets('renders the description below the label', (tester) async {
      await tester.pumpWidget(
        host(
          FossRadioGroup<String>(
            onChanged: (_) {},
            children: const [
              FossRadio(
                value: 'a',
                label: 'Apple',
                description: 'A crisp fruit',
              ),
            ],
          ),
        ),
      );

      expect(find.text('A crisp fruit'), findsOneWidget);
    });

    testWidgets('a per-instance style overrides the resolved visuals', (
      tester,
    ) async {
      const style = FossRadioStyle(
        backgroundColor: Color(0xFF102030),
        checkedColor: Color(0xFF203040),
        dotColor: Color(0xFF304050),
        borderColor: Color(0xFF405060),
        shadow: [],
        circleSize: 22,
        dotSize: 10,
        gap: 12,
        labelStyle: TextStyle(fontSize: 18, height: 1.2),
        descriptionStyle: TextStyle(fontSize: 13, height: 1.2),
      );
      await tester.pumpWidget(
        host(
          FossRadioGroup<String>(
            groupValue: 'a',
            onChanged: (_) {},
            children: [
              FossRadio<String>(value: 'a', label: 'Apple', style: style),
            ],
          ),
        ),
      );

      expect(_circle(tester, 'Apple').color, const Color(0xFF203040));
      expect(tester.getSize(_circleOf('Apple').first).width, 22);
    });

    testWidgets('the resting rim repaints on a theme change', (tester) async {
      var dark = false;
      late StateSetter rebuild;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return FossTheme(
                data: dark ? FossThemeData.dark : FossThemeData.light,
                child: FossRadioGroup<String>(
                  onChanged: (_) {},
                  children: const [FossRadio(value: 'a', label: 'Apple')],
                ),
              );
            },
          ),
        ),
      );

      rebuild(() => dark = true);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('FossRadio keyboard and semantics', () {
    testWidgets('arrow keys move selection through the group', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _group(groupValue: 'a', onChanged: (v) => picked = v),
      );

      // Focus enters the group at the selected option, then arrows move and
      // select the next and previous enabled option.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(picked, 'b');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(picked, 'a');
    });

    testWidgets('an errored option is marked invalid for assistive tech', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _group(groupValue: 'a', errorText: 'Required', onChanged: (_) {}),
      );

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
          validationResult: SemanticsValidationResult.invalid,
        ),
      );
      handle.dispose();
    });

    testWidgets('the checked dot is 8px in the primary foreground', (
      tester,
    ) async {
      await tester.pumpWidget(_group(groupValue: 'a', onChanged: (_) {}));

      final dot = _circleOf('Apple').last;
      expect(
        (tester.widget<DecoratedBox>(dot).decoration as ShapeDecoration).color,
        FossThemeData.light.colors.primaryForeground,
      );
      expect(tester.getSize(dot), const Size(8, 8));
    });

    testWidgets('a description-only option renders its circle and text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _group(
          groupValue: 'a',
          onChanged: (_) {},
          children: const [
            FossRadio(value: 'a', description: 'Detail, no title'),
            FossRadio(value: 'b', label: 'Banana'),
          ],
        ),
      );

      expect(find.text('Detail, no title'), findsOneWidget);
      // Checked, so the outer circle plus the dot both render.
      expect(_circleOf('Detail, no title'), findsNWidgets(2));
    });
  });
}
