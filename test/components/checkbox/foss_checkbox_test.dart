import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

import 'host.dart';

Finder _boxesOf(Finder owner) =>
    find.descendant(of: owner, matching: find.byType(DecoratedBox));

ShapeDecoration _decoration(WidgetTester tester, Finder finder) =>
    tester.widget<DecoratedBox>(finder).decoration as ShapeDecoration;

// The control box is the innermost decorated box; in the card variant the card
// surface is an outer decorated box, so the box is always the last one.
ShapeDecoration _box(WidgetTester tester, Finder owner) =>
    _decoration(tester, _boxesOf(owner).last);

Widget _group({
  Set<String> values = const {},
  ValueChanged<Set<String>>? onChanged,
  String? label,
  String? errorText,
  bool enabled = true,
  FossCheckboxGroupVariant variant = FossCheckboxGroupVariant.plain,
  List<Widget> children = const [
    FossCheckboxItem(value: 'a', label: 'Apple'),
    FossCheckboxItem(value: 'b', label: 'Banana'),
  ],
}) => host(
  FossCheckboxGroup<String>(
    values: values,
    onChanged: onChanged,
    label: label,
    errorText: errorText,
    enabled: enabled,
    variant: variant,
    children: children,
  ),
);

void main() {
  final colors = FossThemeData.light.colors;

  group('FossCheckbox standalone', () {
    testWidgets('unchecked tap reports true', (tester) async {
      bool? next;
      await tester.pumpWidget(
        host(FossCheckbox(label: 'Terms', onChanged: (v) => next = v)),
      );

      await tester.tap(find.text('Terms'));
      expect(next, isTrue);
    });

    testWidgets('checked tap reports false', (tester) async {
      bool? next;
      await tester.pumpWidget(
        host(
          FossCheckbox(value: true, label: 'Terms', onChanged: (v) => next = v),
        ),
      );

      await tester.tap(find.text('Terms'));
      expect(next, isFalse);
    });

    testWidgets('indeterminate tap reports true', (tester) async {
      bool? next;
      await tester.pumpWidget(
        host(
          FossCheckbox(value: null, label: 'Terms', onChanged: (v) => next = v),
        ),
      );

      await tester.tap(find.text('Terms'));
      expect(next, isTrue);
    });

    testWidgets('checked fills primary and drops the border', (tester) async {
      await tester.pumpWidget(
        host(const FossCheckbox(value: true, label: 'Terms')),
      );

      final box = _box(tester, find.byType(FossCheckbox));
      expect(box.color, colors.primary);
      expect(
        (box.shape as RoundedSuperellipseBorder).side.style,
        BorderStyle.none,
      );
    });

    testWidgets('unchecked uses the input border on the surface', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const FossCheckbox(label: 'Terms')),
      );

      final box = _box(tester, find.byType(FossCheckbox));
      expect(box.color, colors.background);
      expect(
        (box.shape as RoundedSuperellipseBorder).side.color,
        colors.input,
      );
    });

    testWidgets('indeterminate keeps the bordered surface box', (tester) async {
      await tester.pumpWidget(
        host(const FossCheckbox(value: null, label: 'Terms')),
      );

      final box = _box(tester, find.byType(FossCheckbox));
      expect(box.color, colors.background);
      expect(
        (box.shape as RoundedSuperellipseBorder).side.color,
        colors.input,
      );
    });

    testWidgets('errorText shows the caption and deepens the border', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const FossCheckbox(label: 'Terms', errorText: 'Required')),
      );

      expect(find.text('Required'), findsOneWidget);
      expect(
        (_box(tester, find.byType(FossCheckbox)).shape
                as RoundedSuperellipseBorder)
            .side
            .color,
        colors.destructive.withValues(alpha: 0.36),
      );
    });

    testWidgets('null onChanged blocks the tap', (tester) async {
      await tester.pumpWidget(
        host(const FossCheckbox(label: 'Terms')),
      );

      // No callback wired; tapping must not throw.
      await tester.tap(find.text('Terms'), warnIfMissed: false);
      expect(tester.takeException(), isNull);
    });
  });

  group('FossCheckboxGroup selection', () {
    testWidgets('tapping an unchecked option adds it to a fresh set', (
      tester,
    ) async {
      const original = {'a'};
      Set<String>? next;
      await tester.pumpWidget(
        _group(values: original, onChanged: (v) => next = v),
      );

      await tester.tap(find.text('Banana'));

      expect(next, {'a', 'b'});
      expect(original, {'a'}); // the incoming set is never mutated
    });

    testWidgets('tapping a checked option removes it', (tester) async {
      Set<String>? next;
      await tester.pumpWidget(
        _group(values: const {'a', 'b'}, onChanged: (v) => next = v),
      );

      await tester.tap(find.text('Apple'));

      expect(next, {'b'});
    });

    testWidgets('checked option fills primary, unchecked keeps the border', (
      tester,
    ) async {
      await tester.pumpWidget(
        _group(values: const {'a'}, onChanged: (_) {}),
      );

      expect(
        _box(tester, find.byType(FossCheckboxItem<String>).first).color,
        colors.primary,
      );
      final banana = _box(
        tester,
        find.byType(FossCheckboxItem<String>).last,
      );
      expect(banana.color, colors.background);
      expect(
        (banana.shape as RoundedSuperellipseBorder).side.color,
        colors.input,
      );
    });
  });

  group('FossCheckboxGroup disabled', () {
    testWidgets('disabling the group blocks every tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _group(enabled: false, onChanged: (_) => taps++),
      );

      await tester.tap(find.text('Apple'), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('a disabled option blocks only itself', (tester) async {
      Set<String>? next;
      await tester.pumpWidget(
        _group(
          onChanged: (v) => next = v,
          children: const [
            FossCheckboxItem(value: 'a', label: 'Apple', enabled: false),
            FossCheckboxItem(value: 'b', label: 'Banana'),
          ],
        ),
      );

      await tester.tap(find.text('Apple'), warnIfMissed: false);
      expect(next, isNull);

      await tester.tap(find.text('Banana'));
      expect(next, {'b'});
    });
  });

  group('FossCheckboxGroup captions', () {
    testWidgets('renders the label above the options', (tester) async {
      await tester.pumpWidget(_group(label: 'Fruit', onChanged: (_) {}));
      expect(find.text('Fruit'), findsOneWidget);
    });

    testWidgets('errorText shows the caption and deepens the border', (
      tester,
    ) async {
      await tester.pumpWidget(
        _group(errorText: 'Pick one', onChanged: (_) {}),
      );

      expect(find.text('Pick one'), findsOneWidget);
      expect(
        (_box(tester, find.byType(FossCheckboxItem<String>).first).shape
                as RoundedSuperellipseBorder)
            .side
            .color,
        colors.destructive.withValues(alpha: 0.36),
      );
    });
  });

  group('FossCheckboxGroup card variant', () {
    testWidgets('checked card lifts its border and fill', (tester) async {
      await tester.pumpWidget(
        _group(
          variant: FossCheckboxGroupVariant.card,
          values: const {'a'},
          onChanged: (_) {},
        ),
      );

      final card = _decoration(
        tester,
        _boxesOf(find.byType(FossCheckboxItem<String>).first).first,
      );
      expect(
        card.color,
        colors.accent.withValues(alpha: colors.accent.a * 0.5),
      );
      expect(
        (card.shape as RoundedSuperellipseBorder).side.color,
        colors.primary.withValues(alpha: 0.48),
      );

      final rest = _decoration(
        tester,
        _boxesOf(find.byType(FossCheckboxItem<String>).last).first,
      );
      expect(rest.color, isNull);
      expect(
        (rest.shape as RoundedSuperellipseBorder).side.color,
        colors.border,
      );
    });
  });

  group('FossCheckbox structure', () {
    testWidgets('renders a bare box without text', (tester) async {
      await tester.pumpWidget(
        host(
          FossCheckboxGroup<String>(
            onChanged: (_) {},
            children: const [FossCheckboxItem(value: 'a')],
          ),
        ),
      );

      expect(find.byType(FossCheckboxItem<String>), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
    });

    testWidgets('item used outside a group throws', (tester) async {
      await tester.pumpWidget(
        host(const FossCheckboxItem<String>(value: 'a')),
      );
      expect(tester.takeException(), isA<FlutterError>());
    });

    testWidgets('dark lifts the unchecked fill off the surface', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossTheme(
            data: FossThemeData.dark,
            child: const FossCheckbox(label: 'Terms'),
          ),
        ),
      );

      expect(
        _box(tester, find.byType(FossCheckbox)).color,
        isNot(FossThemeData.dark.colors.background),
      );
    });
  });

  group('FossCheckbox responsive', () {
    testWidgets('box holds its size under 2x text scale', (tester) async {
      await tester.pumpWidget(host(const FossCheckbox(label: 'Terms')));
      final base = tester.getSize(_boxesOf(find.byType(FossCheckbox)).last);

      await tester.pumpWidget(
        host(
          MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: const FossCheckbox(label: 'Terms'),
          ),
        ),
      );

      expect(tester.getSize(_boxesOf(find.byType(FossCheckbox)).last), base);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays the box after the label in RTL', (tester) async {
      await tester.pumpWidget(
        host(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: FossCheckbox(label: 'Terms'),
          ),
        ),
      );

      expect(
        tester.getCenter(_boxesOf(find.byType(FossCheckbox)).last).dx,
        greaterThan(tester.getCenter(find.text('Terms')).dx),
      );
    });
  });

  group('FossCheckbox accessibility', () {
    testWidgets('exposes the checkbox role and checked state', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(FossCheckbox(value: true, label: 'Terms', onChanged: (_) {})),
      );

      expect(
        tester.getSemantics(find.byType(FossCheckbox)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          label: 'Terms',
        ),
      );
      handle.dispose();
    });

    testWidgets('indeterminate announces the mixed state', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(FossCheckbox(value: null, label: 'Terms', onChanged: (_) {})),
      );

      expect(
        tester.getSemantics(find.byType(FossCheckbox)),
        matchesSemantics(
          hasCheckedState: true,
          isCheckStateMixed: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          label: 'Terms',
        ),
      );
      handle.dispose();
    });

    testWidgets('meets the minimum tap target', (tester) async {
      await tester.pumpWidget(host(const FossCheckbox(label: 'Terms')));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });
}
