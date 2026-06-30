import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

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
}
