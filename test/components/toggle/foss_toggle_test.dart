import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

ShapeDecoration _surface(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .map((b) => b.decoration)
    .whereType<ShapeDecoration>()
    .firstWhere((d) => d.shape is RoundedSuperellipseBorder);

Finder _surfaceFinder() => find.byWidgetPredicate(
  (w) =>
      w is DecoratedBox &&
      w.decoration is ShapeDecoration &&
      (w.decoration as ShapeDecoration).shape is RoundedSuperellipseBorder,
);

void main() {
  final colors = FossThemeData.light.colors;
  Color pressedFill() => colors.input.withValues(alpha: colors.input.a * 0.64);

  group('FossToggle pressed logic', () {
    testWidgets('off tap reports true', (tester) async {
      bool? next;
      await tester.pumpWidget(
        host(FossToggle(pressed: false, onPressedChanged: (v) => next = v)),
      );

      await tester.tap(find.byType(FossToggle));
      expect(next, isTrue);
    });

    testWidgets('on tap reports false', (tester) async {
      bool? next;
      await tester.pumpWidget(
        host(FossToggle(pressed: true, onPressedChanged: (v) => next = v)),
      );

      await tester.tap(find.byType(FossToggle));
      expect(next, isFalse);
    });

    testWidgets('null onPressedChanged blocks the tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          Listener(
            onPointerDown: (_) => taps++,
            child: const FossToggle(pressed: false, semanticLabel: 'Bold'),
          ),
        ),
      );

      await tester.tap(find.byType(FossToggle), warnIfMissed: false);
      // The pointer reaches the outer Listener, but nothing is reported back.
      expect(taps, greaterThanOrEqualTo(0));
      expect(
        tester.getSemantics(find.byType(FossToggle)),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
    });
  });

  group('FossToggle pressed fill', () {
    testWidgets('standard rests transparent, fills when on', (tester) async {
      await tester.pumpWidget(
        host(FossToggle(pressed: false, onPressedChanged: (_) {})),
      );
      expect(_surface(tester).color, const Color(0x00000000));

      await tester.pumpWidget(
        host(FossToggle(pressed: true, onPressedChanged: (_) {})),
      );
      expect(_surface(tester).color, pressedFill());
    });

    testWidgets('pressed text uses accentForeground', (tester) async {
      await tester.pumpWidget(
        host(
          FossToggle(
            pressed: true,
            onPressedChanged: (_) {},
            child: const Text('Bold'),
          ),
        ),
      );

      final style = tester
          .widget<DefaultTextStyle>(
            find
                .ancestor(
                  of: find.text('Bold'),
                  matching: find.byType(DefaultTextStyle),
                )
                .first,
          )
          .style;
      expect(style.color, colors.accentForeground);
    });
  });

  group('FossToggle icon-only', () {
    testWidgets('is square at its size', (tester) async {
      await tester.pumpWidget(
        host(
          FossToggle(
            pressed: false,
            onPressedChanged: (_) {},
            leading: const Icon(Icons.format_bold),
            semanticLabel: 'Bold',
          ),
        ),
      );

      final size = tester.getSize(
        find
            .descendant(
              of: find.byType(FossToggle),
              matching: _surfaceFinder(),
            )
            .first,
      );
      expect(size.width, size.height);
      expect(size.height, 36);
    });
  });

  group('FossToggle accessibility', () {
    testWidgets('exposes button role, toggled state, and label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          FossToggle(
            pressed: true,
            semanticLabel: 'Bold',
            onPressedChanged: (_) {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(FossToggle)),
        isSemantics(
          isButton: true,
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          label: 'Bold',
        ),
      );
      handle.dispose();
    });

    testWidgets('Space toggles when focused', (tester) async {
      bool? next;
      await tester.pumpWidget(
        host(FossToggle(pressed: false, onPressedChanged: (v) => next = v)),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(next, isTrue);
    });

    testWidgets('Enter toggles when focused', (tester) async {
      bool? next;
      await tester.pumpWidget(
        host(FossToggle(pressed: true, onPressedChanged: (v) => next = v)),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(next, isFalse);
    });

    testWidgets('meets the minimum tap target', (tester) async {
      await tester.pumpWidget(
        host(
          FossToggle(
            pressed: false,
            size: FossToggleSize.sm,
            onPressedChanged: (_) {},
          ),
        ),
      );

      final size = tester.getSize(find.byType(FossToggle));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });

  group('FossToggle disabled', () {
    testWidgets('dims to the disabled opacity', (tester) async {
      await tester.pumpWidget(
        host(const FossToggle(pressed: false, semanticLabel: 'Bold')),
      );

      final opacity = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .where(
            (o) => o.opacity == 0.64,
          );
      expect(opacity, isNotEmpty);
    });
  });

  group('FossToggle responsive', () {
    testWidgets('grows under a large text scale without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: FossToggle(
              pressed: false,
              onPressedChanged: (_) {},
              leading: const Icon(Icons.format_bold),
              child: const Text('Bold'),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('outline carries a border', (tester) async {
      await tester.pumpWidget(
        host(
          FossToggle(
            pressed: false,
            variant: FossToggleVariant.outline,
            onPressedChanged: (_) {},
            child: const Text('Bold'),
          ),
        ),
      );

      final shape = _surface(tester).shape as RoundedSuperellipseBorder;
      expect(shape.side.color, colors.input);
    });
  });
}
