import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

import 'host.dart';

const _tabs = <FossTab<String>>[
  FossTab(value: 'one', label: 'One', content: Text('PanelOne')),
  FossTab(value: 'two', label: 'Two', content: Text('PanelTwo')),
  FossTab(value: 'three', label: 'Three', content: Text('PanelThree')),
];

Finder _coloredBox(Color color) => find.byWidgetPredicate(
  (w) => w is ColoredBox && w.color.toARGB32() == color.toARGB32(),
);

Finder _filled(Color color) => find.byWidgetPredicate(
  (w) =>
      w is DecoratedBox &&
      w.decoration is ShapeDecoration &&
      (w.decoration as ShapeDecoration).color?.toARGB32() == color.toARGB32(),
);

void main() {
  final colors = FossThemeData.light.colors;

  group('FossTabsStyle.merge', () {
    test('other wins field by field, this fills the gaps', () {
      const base = FossTabsStyle(
        barColor: Color(0xFF111111),
        activeForeground: Color(0xFF222222),
      );
      const over = FossTabsStyle(activeForeground: Color(0xFF333333));

      final merged = base.merge(over);
      expect(merged.activeForeground, const Color(0xFF333333));
      expect(merged.barColor, const Color(0xFF111111));
    });

    test('null other returns this', () {
      const base = FossTabsStyle(barColor: Color(0xFF111111));
      expect(base.merge(null), same(base));
    });
  });

  group('FossTabs selection', () {
    testWidgets('renders every label and the active panel', (tester) async {
      await tester.pumpWidget(
        host(const FossTabs<String>(tabs: _tabs, initialValue: 'one')),
      );
      await tester.pumpAndSettle();

      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(find.text('PanelOne'), findsOneWidget);
      expect(find.text('PanelTwo'), findsNothing);
    });

    testWidgets('tap swaps the panel when uncontrolled', (tester) async {
      await tester.pumpWidget(
        host(const FossTabs<String>(tabs: _tabs, initialValue: 'one')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();

      expect(find.text('PanelTwo'), findsOneWidget);
      expect(find.text('PanelOne'), findsNothing);
    });

    testWidgets('controlled tab reports onChanged, holds value', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        host(
          FossTabs<String>(
            tabs: _tabs,
            value: 'one',
            onChanged: (v) => picked = v,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();

      expect(picked, 'two');
      // Parent never updated value, so the panel stays.
      expect(find.text('PanelOne'), findsOneWidget);
    });

    testWidgets('disabled tab does not select', (tester) async {
      String? picked;
      await tester.pumpWidget(
        host(
          FossTabs<String>(
            value: 'one',
            onChanged: (v) => picked = v,
            tabs: const [
              FossTab(value: 'one', label: 'One', content: Text('PanelOne')),
              FossTab(
                value: 'two',
                label: 'Two',
                enabled: false,
                content: Text('PanelTwo'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Two'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(picked, isNull);
    });
  });

  group('FossTabs keyboard', () {
    testWidgets('arrow moves focus, Space activates, skipping disabled', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        host(
          FossTabs<String>(
            value: 'one',
            onChanged: (v) => picked = v,
            tabs: const [
              FossTab(value: 'one', label: 'One', content: Text('PanelOne')),
              FossTab(
                value: 'two',
                label: 'Two',
                enabled: false,
                content: Text('PanelTwo'),
              ),
              FossTab(
                value: 'three',
                label: 'Three',
                content: Text('PanelThree'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('One'));
      await tester.pumpAndSettle();
      expect(picked, 'one');

      // Right skips the disabled middle tab and lands on Three.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(picked, 'three');
    });

    testWidgets('Home and End jump to the ends', (tester) async {
      String? picked;
      await tester.pumpWidget(
        host(
          FossTabs<String>(
            value: 'two',
            onChanged: (v) => picked = v,
            tabs: _tabs,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, 'three');

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, 'one');
    });
  });

  group('FossTabs variants and indicator', () {
    testWidgets('segmented pill fills the background role in light', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const FossTabs<String>(tabs: _tabs, initialValue: 'one')),
      );
      await tester.pumpAndSettle();
      expect(_filled(colors.background), findsWidgets);
    });

    testWidgets('segmented pill lifts to input in dark', (tester) async {
      await tester.pumpWidget(
        host(
          const FossTheme(
            data: FossThemeData.dark,
            child: FossTabs<String>(tabs: _tabs, initialValue: 'one'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _filled(FossThemeData.dark.colors.input),
        findsWidgets,
      );
    });

    testWidgets('underline draws a primary bar', (tester) async {
      await tester.pumpWidget(
        host(
          const FossTabs<String>(
            tabs: _tabs,
            initialValue: 'one',
            variant: FossTabsVariant.underline,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_coloredBox(colors.primary), findsOneWidget);
    });

    testWidgets('vertical orientation renders strip and panel', (tester) async {
      await tester.pumpWidget(
        host(
          const FossTabs<String>(
            tabs: _tabs,
            initialValue: 'one',
            orientation: FossTabsOrientation.vertical,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('One'), findsOneWidget);
      expect(find.text('PanelOne'), findsOneWidget);
    });

    testWidgets('indicator moves when the selection changes', (tester) async {
      await tester.pumpWidget(
        host(const FossTabs<String>(tabs: _tabs, initialValue: 'one')),
      );
      await tester.pumpAndSettle();
      final firstLeft = tester.getTopLeft(_filled(colors.background)).dx;

      await tester.tap(find.text('Three'));
      await tester.pumpAndSettle();
      final lastLeft = tester.getTopLeft(_filled(colors.background)).dx;

      expect(lastLeft, greaterThan(firstLeft));
    });
  });

  group('FossTabs accessibility', () {
    testWidgets('the active tab exposes the selected tab role', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const FossTabs<String>(tabs: _tabs, initialValue: 'two')),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.bySemanticsLabel('Two')),
        isSemantics(isSelected: true, hasSelectedState: true, label: 'Two'),
      );
      handle.dispose();
    });

    testWidgets('reduced motion swaps without scheduling animation', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: FossTabs<String>(tabs: _tabs, initialValue: 'one'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Two'));
      await tester.pump();

      expect(find.text('PanelTwo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RTL mirrors the indicator to the right', (tester) async {
      await tester.pumpWidget(
        host(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: FossTabs<String>(tabs: _tabs, initialValue: 'one'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Under RTL the first tab sits at the trailing (right) side, so its pill
      // starts past the strip's horizontal center.
      final stripCenter = tester.getCenter(find.text('Two')).dx;
      final pillLeft = tester.getTopLeft(_filled(colors.background)).dx;
      expect(pillLeft, greaterThan(stripCenter));
    });
  });
}
