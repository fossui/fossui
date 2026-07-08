import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

ShapeDecoration _decorationWhere(
  WidgetTester tester,
  bool Function(ShapeBorder shape) test,
) {
  final box = tester
      .widgetList<DecoratedBox>(find.byType(DecoratedBox))
      .map((b) => b.decoration)
      .whereType<ShapeDecoration>()
      .firstWhere((d) => test(d.shape));
  return box;
}

ShapeDecoration _track(WidgetTester tester) =>
    _decorationWhere(tester, (s) => s is StadiumBorder);

Finder _thumb() => find.byWidgetPredicate(
  (w) =>
      w is DecoratedBox &&
      w.decoration is ShapeDecoration &&
      (w.decoration as ShapeDecoration).shape is CircleBorder,
);

void main() {
  final colors = FossThemeData.light.colors;

  group('FossSwitch toggle', () {
    testWidgets('off tap reports true', (tester) async {
      bool? next;
      await tester.pumpWidget(
        host(FossSwitch(value: false, onChanged: (v) => next = v)),
      );

      await tester.tap(find.byType(FossSwitch));
      expect(next, isTrue);
    });

    testWidgets('on tap reports false', (tester) async {
      bool? next;
      await tester.pumpWidget(
        host(FossSwitch(value: true, onChanged: (v) => next = v)),
      );

      await tester.tap(find.byType(FossSwitch));
      expect(next, isFalse);
    });

    testWidgets('Space toggles when focused', (tester) async {
      bool? next;
      await tester.pumpWidget(
        host(FossSwitch(value: false, onChanged: (v) => next = v)),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(next, isTrue);
    });

    testWidgets('null onChanged blocks the tap', (tester) async {
      await tester.pumpWidget(host(const FossSwitch(value: false)));

      await tester.tap(find.byType(FossSwitch), warnIfMissed: false);
      expect(tester.takeException(), isNull);
    });
  });

  group('FossSwitch track', () {
    testWidgets('off uses the input track', (tester) async {
      await tester.pumpWidget(host(const FossSwitch(value: false)));
      expect(_track(tester).color?.toARGB32(), colors.input.toARGB32());
    });

    testWidgets('on uses the primary track', (tester) async {
      await tester.pumpWidget(host(const FossSwitch(value: true)));
      await tester.pumpAndSettle();
      expect(_track(tester).color?.toARGB32(), colors.primary.toARGB32());
    });

    testWidgets('thumb fills the background role', (tester) async {
      await tester.pumpWidget(host(const FossSwitch(value: false)));
      final thumb =
          tester.widget<DecoratedBox>(_thumb()).decoration as ShapeDecoration;
      expect(thumb.color, colors.background);
    });

    testWidgets('thumb rests leading when off, trailing when on', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FossSwitch(value: false)));
      final offX = tester.getCenter(_thumb()).dx;

      await tester.pumpWidget(host(const FossSwitch(value: true)));
      await tester.pumpAndSettle();
      final onX = tester.getCenter(_thumb()).dx;

      expect(onX, greaterThan(offX));
    });
  });

  group('FossSwitch accessibility', () {
    testWidgets('exposes the toggle role, state, and label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          FossSwitch(
            value: true,
            semanticsLabel: 'Wi-Fi',
            onChanged: (_) {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(FossSwitch)),
        matchesSemantics(
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          label: 'Wi-Fi',
        ),
      );
      handle.dispose();
    });

    testWidgets('disabled announces the disabled toggle', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const FossSwitch(value: false, semanticsLabel: 'Wi-Fi')),
      );

      expect(
        tester.getSemantics(find.byType(FossSwitch)),
        matchesSemantics(
          hasToggledState: true,
          hasEnabledState: true,
          label: 'Wi-Fi',
        ),
      );
      handle.dispose();
    });

    testWidgets('meets the minimum tap target', (tester) async {
      await tester.pumpWidget(
        host(FossSwitch(value: false, onChanged: (_) {})),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });

  group('FossSwitch responsive and motion', () {
    testWidgets('track holds its size under 2x text scale', (tester) async {
      await tester.pumpWidget(host(const FossSwitch(value: false)));
      final base = tester.getSize(find.byType(FossSwitch));

      await tester.pumpWidget(
        host(
          MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: const FossSwitch(value: false),
          ),
        ),
      );

      expect(tester.getSize(find.byType(FossSwitch)), base);
    });

    testWidgets('thumb mirrors sides under RTL', (tester) async {
      await tester.pumpWidget(
        host(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: FossSwitch(value: false),
          ),
        ),
      );
      final offX = tester.getCenter(_thumb()).dx;

      await tester.pumpWidget(
        host(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: FossSwitch(value: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final onX = tester.getCenter(_thumb()).dx;

      // On rests to the left of off under RTL: the mirror of the LTR layout.
      expect(onX, lessThan(offX));
    });

    testWidgets('reduced motion toggles without scheduling animation', (
      tester,
    ) async {
      bool? next;
      await tester.pumpWidget(
        host(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: FossSwitch(value: false, onChanged: (v) => next = v),
          ),
        ),
      );

      await tester.tap(find.byType(FossSwitch));
      expect(next, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark on keeps the primary track', (tester) async {
      await tester.pumpWidget(
        host(
          const FossTheme(
            data: FossThemeData.dark,
            child: FossSwitch(value: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _track(tester).color?.toARGB32(),
        FossThemeData.dark.colors.primary.toARGB32(),
      );
    });
  });

  group('FossSwitch drag', () {
    // A timed horizontal drag that ends with real velocity in the [dx]
    // direction, so the release resolves through the flick branch.
    Future<void> flick(WidgetTester tester, double dx) async {
      final center = tester.getCenter(find.byType(FossSwitch));
      final gesture = await tester.startGesture(center);
      for (var i = 1; i <= 8; i++) {
        await gesture.moveTo(
          center + Offset(dx * i / 8, 0),
          timeStamp: Duration(milliseconds: i * 4),
        );
      }
      await gesture.up(timeStamp: const Duration(milliseconds: 36));
      await tester.pump();
    }

    testWidgets('a still drag release toggles', (tester) async {
      bool? next;
      await tester.pumpWidget(
        host(FossSwitch(value: false, onChanged: (v) => next = v)),
      );

      await tester.drag(find.byType(FossSwitch), const Offset(24, 0));
      await tester.pump();

      expect(next, isTrue);
    });

    testWidgets('a flick to the trailing edge turns on', (tester) async {
      bool? next;
      await tester.pumpWidget(
        host(FossSwitch(value: false, onChanged: (v) => next = v)),
      );

      await flick(tester, 24);

      expect(next, isTrue);
    });

    testWidgets('a flick back to the leading edge turns off', (tester) async {
      bool? next;
      await tester.pumpWidget(
        host(FossSwitch(value: true, onChanged: (v) => next = v)),
      );

      await flick(tester, -24);

      expect(next, isFalse);
    });

    testWidgets('RTL flick to the visual end turns on', (tester) async {
      bool? next;
      await tester.pumpWidget(
        host(
          Directionality(
            textDirection: TextDirection.rtl,
            child: FossSwitch(value: false, onChanged: (v) => next = v),
          ),
        ),
      );

      // Under RTL the visual end is the left edge, so a leftward flick is on.
      await flick(tester, -24);

      expect(next, isTrue);
    });
  });

  group('FossSwitch style and focus ring', () {
    testWidgets('style overrides the track and thumb geometry', (tester) async {
      await tester.pumpWidget(
        host(
          const FossSwitch(
            value: false,
            style: FossSwitchStyle(
              trackWidth: 44,
              trackHeight: 26,
              thumbSize: 24,
            ),
          ),
        ),
      );

      final boxes = tester.widgetList<SizedBox>(
        find.descendant(
          of: find.byType(FossSwitch),
          matching: find.byType(SizedBox),
        ),
      );
      expect(boxes.any((b) => b.width == 44 && b.height == 26), isTrue);
      expect(boxes.any((b) => b.width == 24 && b.height == 24), isTrue);
    });

    testWidgets('the focus ring survives a rebuild', (tester) async {
      late StateSetter setOuter;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return FossSwitch(value: false, onChanged: (_) {});
            },
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // A rebuild while focused re-creates the ring painter, exercising its
      // repaint check.
      setOuter(() {});
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('FossSwitch geometry and states', () {
    testWidgets('the thumb shadow is softened to a faint tint', (tester) async {
      await tester.pumpWidget(host(const FossSwitch(value: false)));

      final thumb =
          tester.widget<DecoratedBox>(_thumb().first).decoration
              as ShapeDecoration;
      expect(thumb.shadows, isNotNull);
      expect(thumb.shadows!.first.color.a, closeTo(0.05, 0.001));
    });

    testWidgets('the thumb travels 16px from off to on', (tester) async {
      await tester.pumpWidget(host(const FossSwitch(value: false)));
      await tester.pumpAndSettle();
      final offX = tester.getCenter(_thumb().first).dx;

      await tester.pumpWidget(host(const FossSwitch(value: true)));
      await tester.pumpAndSettle();
      final onX = tester.getCenter(_thumb().first).dx;

      expect(onX - offX, closeTo(16, 0.5));
    });

    testWidgets('a tap-down squishes the thumb along the travel axis', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FossSwitch(value: false, onChanged: (_) {})),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(FossSwitch)),
      );
      // A drag past the touch slop presses the switch; hold so the squish
      // settles at its full stretch.
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final scales = tester
          .widgetList<Transform>(
            find.descendant(
              of: find.byType(FossSwitch),
              matching: find.byType(Transform),
            ),
          )
          .map((t) => t.transform.entry(0, 0));
      expect(scales, contains(closeTo(1.1, 0.01)));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('keyboard focus paints the ring, absent when unfocused', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FossSwitch(value: false, onChanged: (_) {})),
      );
      final ring = find.descendant(
        of: find.byType(FossSwitch),
        matching: find.byType(CustomPaint),
      );
      expect(ring, findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(ring, findsOneWidget);
    });

    testWidgets('a disabled switch dims to 0.64', (tester) async {
      await tester.pumpWidget(host(const FossSwitch(value: false)));

      expect(
        find.descendant(
          of: find.byType(FossSwitch),
          matching: find.byWidgetPredicate(
            (w) => w is Opacity && w.opacity == 0.64,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('reduced motion settles without a pending animation', (
      tester,
    ) async {
      Widget switchAt({required bool on}) => host(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: FossSwitch(value: on, onChanged: (_) {}),
        ),
      );

      await tester.pumpWidget(switchAt(on: false));
      await tester.pumpWidget(switchAt(on: true));
      await tester.pump();

      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
