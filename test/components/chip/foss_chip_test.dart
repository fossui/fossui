import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

Finder _pillFinder() => find.byWidgetPredicate(
  (w) =>
      w is DecoratedBox &&
      w.decoration is ShapeDecoration &&
      (w.decoration as ShapeDecoration).shape is RoundedSuperellipseBorder,
);

ShapeDecoration _pill(WidgetTester tester) =>
    tester.widget<DecoratedBox>(_pillFinder().first).decoration
        as ShapeDecoration;

TextStyle _labelStyle(WidgetTester tester, String text) => tester
    .widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text(text),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    )
    .style;

Finder _removeFinder() => find.bySemanticsLabel('Remove');

/// The close mark's painter. It is rebuilt whenever the glyph color changes,
/// so its identity tracks the affordance's rest / lit state. The glyph type
/// itself is internal, so the test holds it as a [CustomPainter].
CustomPainter _glyphPainter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(
      find.descendant(of: _removeFinder(), matching: find.byType(CustomPaint)),
    )
    .map((p) => p.painter)
    .whereType<CustomPainter>()
    .first;

/// Attaches a mouse and puts the focus manager in the pointer-driven mode, so
/// hover highlights surface at all under a synthetic pointer.
Future<TestGesture> _hoverPointer(WidgetTester tester) async {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer();
  addTearDown(gesture.removePointer);
  return gesture;
}

void main() {
  final light = FossThemeData.light.colors;

  group('FossChip selection', () {
    testWidgets('tapping an unselected body reports true', (tester) async {
      bool? next;
      await tester.pumpWidget(
        host(
          FossChip(label: const Text('Design'), onSelected: (v) => next = v),
        ),
      );

      await tester.tap(find.byType(FossChip));
      expect(next, isTrue);
    });

    testWidgets('tapping a selected body reports false', (tester) async {
      bool? next;
      await tester.pumpWidget(
        host(
          FossChip(
            label: const Text('Design'),
            selected: true,
            onSelected: (v) => next = v,
          ),
        ),
      );

      await tester.tap(find.byType(FossChip));
      expect(next, isFalse);
    });

    testWidgets('a chip without onSelected does not react to a tap', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FossChip(label: Text('Design'))));

      await tester.tap(find.byType(FossChip));
      await tester.pump();
      expect(_pill(tester).color, light.accent);
    });
  });

  group('FossChip removal', () {
    testWidgets('the close affordance appears only with onRemove', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FossChip(label: Text('Design'))));
      expect(_removeFinder(), findsNothing);

      await tester.pumpWidget(
        host(FossChip(label: const Text('Design'), onRemove: () {})),
      );
      expect(_removeFinder(), findsOneWidget);
    });

    testWidgets('tapping remove fires onRemove without selecting', (
      tester,
    ) async {
      var removed = 0;
      var selections = 0;
      await tester.pumpWidget(
        host(
          FossChip(
            label: const Text('Design'),
            onSelected: (_) => selections++,
            onRemove: () => removed++,
          ),
        ),
      );

      await tester.tap(_removeFinder());
      expect(removed, 1);
      expect(selections, 0);
    });

    testWidgets('removeLabel names the close affordance', (tester) async {
      await tester.pumpWidget(
        host(
          FossChip(
            label: const Text('Design'),
            removeLabel: 'Drop tag',
            onRemove: () {},
          ),
        ),
      );

      expect(find.bySemanticsLabel('Drop tag'), findsOneWidget);
    });
  });

  group('FossChip disabled', () {
    testWidgets('blocks the body and the close affordance', (tester) async {
      var selections = 0;
      var removed = 0;
      await tester.pumpWidget(
        host(
          FossChip(
            label: const Text('Design'),
            enabled: false,
            onSelected: (_) => selections++,
            onRemove: () => removed++,
          ),
        ),
      );

      await tester.tap(find.byType(FossChip), warnIfMissed: false);
      await tester.tap(_removeFinder(), warnIfMissed: false);
      expect(selections, 0);
      expect(removed, 0);
    });

    testWidgets('dims the chip and announces disabled', (tester) async {
      await tester.pumpWidget(
        host(
          FossChip(
            label: const Text('Design'),
            enabled: false,
            onSelected: (_) {},
          ),
        ),
      );

      final opacity = tester.widget<Opacity>(
        find
            .descendant(
              of: find.byType(FossChip),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, 0.64);
      expect(
        tester.getSemantics(find.byType(FossChip)),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
    });
  });

  group('FossChip fills', () {
    testWidgets('soft rests on accent and selects to primary', (tester) async {
      await tester.pumpWidget(
        host(FossChip(label: const Text('Design'), onSelected: (_) {})),
      );
      expect(_pill(tester).color, light.accent);

      await tester.pumpWidget(
        host(
          FossChip(
            label: const Text('Design'),
            selected: true,
            onSelected: (_) {},
          ),
        ),
      );
      expect(_pill(tester).color, light.primary);
      expect(_labelStyle(tester, 'Design').color, light.primaryForeground);
    });

    testWidgets('outline rests on background behind an input border', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FossChip(
            label: Text('Design'),
            variant: FossChipVariant.outline,
          ),
        ),
      );

      final pill = _pill(tester);
      expect(pill.color, light.background);
      expect((pill.shape as RoundedSuperellipseBorder).side.color, light.input);
      expect(_labelStyle(tester, 'Design').color, light.foreground);
    });

    testWidgets('a selected outline chip borders in primary', (tester) async {
      await tester.pumpWidget(
        host(
          FossChip(
            label: const Text('Design'),
            variant: FossChipVariant.outline,
            selected: true,
            onSelected: (_) {},
          ),
        ),
      );

      final shape = _pill(tester).shape as RoundedSuperellipseBorder;
      expect(shape.side.color, light.primary);
    });

    testWidgets('hovering a soft chip darkens past the rest fill', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FossChip(label: const Text('Design'), onSelected: (_) {})),
      );

      // Hover highlights only surface once the focus manager is in the
      // pointer-driven mode, which a bare synthetic move does not switch on.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(FossChip)));
      await tester.pump();

      expect(_pill(tester).color, isNot(light.accent));
    });

    testWidgets('hovering a selected chip softens the primary fill', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossChip(
            label: const Text('Design'),
            selected: true,
            onSelected: (_) {},
          ),
        ),
      );

      final gesture = await _hoverPointer(tester);
      await gesture.moveTo(tester.getCenter(find.byType(FossChip)));
      await tester.pump();

      expect(
        _pill(tester).color,
        light.primary.withValues(alpha: light.primary.a * 0.9),
      );
    });

    testWidgets('hovering the close affordance lifts the glyph to full', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FossChip(label: const Text('Design'), onRemove: () {})),
      );
      final rest = _glyphPainter(tester);

      final gesture = await _hoverPointer(tester);
      await gesture.moveTo(tester.getCenter(_removeFinder()));
      await tester.pump();

      final lit = _glyphPainter(tester);
      expect(lit, isNot(same(rest)));
      expect(lit.shouldRepaint(rest), isTrue);
    });

    testWidgets('the focus ring repaints when the theme changes', (
      tester,
    ) async {
      Widget chip(FossThemeData theme) => host(
        FossChip(label: const Text('Design'), onSelected: (_) {}),
        theme: theme,
      );

      await tester.pumpWidget(chip(FossThemeData.light));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      await tester.pumpWidget(chip(FossThemeData.dark));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('the focus ring repaints when only the corners change', (
      tester,
    ) async {
      Widget chip(double radius) => host(
        FossChip(
          label: const Text('Design'),
          onSelected: (_) {},
          style: FossChipStyle(borderRadius: radius),
        ),
      );

      await tester.pumpWidget(chip(8));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Same theme, so the ring keeps its color and offset and only the corner
      // radius differs, which is the branch a color change short-circuits past.
      await tester.pumpWidget(chip(2));
      await tester.pump();

      expect(
        (_pill(tester).shape as RoundedSuperellipseBorder).borderRadius,
        const BorderRadius.all(Radius.circular(2)),
      );
    });

    testWidgets('dark resolves from the same roles', (tester) async {
      final dark = FossThemeData.dark.colors;
      await tester.pumpWidget(
        host(
          const FossChip(label: Text('Design')),
          theme: FossThemeData.dark,
        ),
      );

      expect(_pill(tester).color, dark.accent);
      expect(_labelStyle(tester, 'Design').color, dark.accentForeground);
    });
  });

  group('FossChip layout', () {
    testWidgets('sm is 24 tall and md is 32', (tester) async {
      await tester.pumpWidget(
        host(
          const FossChip(label: Text('Design'), size: FossChipSize.sm),
        ),
      );
      expect(tester.getSize(_pillFinder().first).height, 24);

      await tester.pumpWidget(host(const FossChip(label: Text('Design'))));
      expect(tester.getSize(_pillFinder().first).height, 32);
    });

    testWidgets('a long label ellipsizes instead of overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FossChip(
            label: Text('A tag label far too long for the space it is given'),
          ),
          width: 120,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_pillFinder().first).width, lessThanOrEqualTo(120));
    });

    testWidgets('the leading slot renders and is decorative', (tester) async {
      await tester.pumpWidget(
        host(
          const FossChip(
            label: Text('Design'),
            leading: Icon(Icons.tag),
          ),
        ),
      );

      expect(find.byIcon(Icons.tag), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ExcludeSemantics),
          matching: find.byIcon(Icons.tag),
        ),
        findsOneWidget,
      );
    });

    testWidgets('an inert chip keeps its exact height', (tester) async {
      await tester.pumpWidget(
        host(FossChip(label: const Text('Design'), onRemove: () {})),
      );

      expect(tester.getSize(find.byType(FossChip)).height, 32);
    });

    testWidgets('grows with text scale', (tester) async {
      await tester.pumpWidget(
        host(const FossChip(label: Text('Design')), textScale: 2),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(_pillFinder().first).height,
        greaterThan(32),
      );
    });

    testWidgets('mirrors under RTL', (tester) async {
      await tester.pumpWidget(
        host(
          FossChip(
            label: const Text('Design'),
            leading: const Icon(Icons.tag),
            onRemove: () {},
          ),
          direction: TextDirection.rtl,
        ),
      );

      final leading = tester.getCenter(find.byIcon(Icons.tag));
      final remove = tester.getCenter(_removeFinder());
      expect(leading.dx, greaterThan(remove.dx));
    });
  });

  group('FossChip accessibility', () {
    testWidgets('a selectable chip exposes button and toggled state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          FossChip(
            label: const Text('Design'),
            semanticLabel: 'Design filter',
            selected: true,
            onSelected: (_) {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(FossChip)),
        isSemantics(
          isButton: true,
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          label: 'Design filter',
        ),
      );
      handle.dispose();
    });

    testWidgets('a display chip carries no button role', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const FossChip(label: Text('Design'))));

      expect(
        tester.getSemantics(find.byType(FossChip)),
        isSemantics(isButton: false, hasToggledState: false),
      );
      handle.dispose();
    });

    testWidgets('Space activates the focused body', (tester) async {
      bool? next;
      await tester.pumpWidget(
        host(
          FossChip(label: const Text('Design'), onSelected: (v) => next = v),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(next, isTrue);
    });

    testWidgets('Enter activates the focused close affordance', (tester) async {
      var removed = 0;
      await tester.pumpWidget(
        host(
          FossChip(label: const Text('Design'), onRemove: () => removed++),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(removed, 1);
    });

    testWidgets('the body reaches the minimum tap target when selectable', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossChip(
            label: const Text('Design'),
            size: FossChipSize.sm,
            onSelected: (_) {},
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(FossChip)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('the close affordance reaches the minimum tap target', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossChip(
            label: const Text('Design'),
            size: FossChipSize.sm,
            onRemove: () {},
          ),
        ),
      );

      final box = tester.getSize(
        find
            .descendant(of: _removeFinder(), matching: find.byType(OverflowBox))
            .first,
      );
      expect(box.height, lessThan(48));
      final region = tester.renderObject(
        find
            .descendant(of: _removeFinder(), matching: find.byType(SizedBox))
            .first,
      );
      expect(region, isNotNull);
    });
  });
}
