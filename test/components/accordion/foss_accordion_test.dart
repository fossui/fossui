import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

const _items = <FossAccordionItem>[
  FossAccordionItem(value: 'a', title: Text('Title A'), child: Text('Panel A')),
  FossAccordionItem(value: 'b', title: Text('Title B'), child: Text('Panel B')),
  FossAccordionItem(value: 'c', title: Text('Title C'), child: Text('Panel C')),
];

// The panel content is always built (it is measured for the height animation),
// so open state is read from the header's exposed expanded flag, not the tree.
bool? _expandedFlag(WidgetTester tester, String title) => tester
    .getSemantics(find.text(title))
    .getSemanticsData()
    .flagsCollection
    .isExpanded
    .toBoolOrNull();

void _expectOpen(WidgetTester tester, String title, {required bool open}) =>
    expect(_expandedFlag(tester, title), open);

bool _hasRing(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .any((c) => c.foregroundPainter?.runtimeType.toString() == '_RingPainter');

Offset _chevronCenter(WidgetTester tester, {int at = 0}) {
  final paints = find.byWidgetPredicate(
    (w) =>
        w is CustomPaint &&
        w.painter?.runtimeType.toString() == '_ChevronPainter',
  );
  return tester.getCenter(paints.at(at));
}

void main() {
  group('render', () {
    testWidgets('shows every title, panels collapsed by default', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FossAccordion(children: _items)));
      expect(find.text('Title A'), findsOneWidget);
      expect(find.text('Title C'), findsOneWidget);
      _expectOpen(tester, 'Title A', open: false);
    });

    testWidgets('initialValue seeds the open section', (tester) async {
      await tester.pumpWidget(
        host(const FossAccordion(initialValue: {'b'}, children: _items)),
      );
      await tester.pumpAndSettle();
      _expectOpen(tester, 'Title B', open: true);
      _expectOpen(tester, 'Title A', open: false);
    });
  });

  group('toggle logic', () {
    testWidgets('tap opens a collapsed section', (tester) async {
      Set<String>? emitted;
      await tester.pumpWidget(
        host(
          FossAccordion(onValueChanged: (v) => emitted = v, children: _items),
        ),
      );
      await tester.tap(find.text('Title A'));
      await tester.pumpAndSettle();
      expect(emitted, {'a'});
      _expectOpen(tester, 'Title A', open: true);
    });

    testWidgets('single mode: opening one closes the other', (tester) async {
      Set<String>? emitted;
      await tester.pumpWidget(
        host(
          FossAccordion(
            initialValue: const {'a'},
            onValueChanged: (v) => emitted = v,
            children: _items,
          ),
        ),
      );
      await tester.tap(find.text('Title B'));
      await tester.pumpAndSettle();
      expect(emitted, {'b'});
      _expectOpen(tester, 'Title A', open: false);
      _expectOpen(tester, 'Title B', open: true);
    });

    testWidgets('collapsible true: re-tapping the open section closes it', (
      tester,
    ) async {
      Set<String>? emitted;
      await tester.pumpWidget(
        host(
          FossAccordion(
            initialValue: const {'a'},
            onValueChanged: (v) => emitted = v,
            children: _items,
          ),
        ),
      );
      await tester.tap(find.text('Title A'));
      await tester.pumpAndSettle();
      expect(emitted, isEmpty);
      _expectOpen(tester, 'Title A', open: false);
    });

    testWidgets('collapsible false: the open section stays open', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        host(
          FossAccordion(
            collapsible: false,
            initialValue: const {'a'},
            onValueChanged: (_) => calls++,
            children: _items,
          ),
        ),
      );
      await tester.tap(find.text('Title A'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      _expectOpen(tester, 'Title A', open: true);
    });

    testWidgets('multiple mode: sections open independently', (tester) async {
      Set<String>? emitted;
      await tester.pumpWidget(
        host(
          FossAccordion(
            multiple: true,
            initialValue: const {'a'},
            onValueChanged: (v) => emitted = v,
            children: _items,
          ),
        ),
      );
      await tester.tap(find.text('Title B'));
      await tester.pumpAndSettle();
      expect(emitted, {'a', 'b'});
      _expectOpen(tester, 'Title A', open: true);
      _expectOpen(tester, 'Title B', open: true);
    });

    testWidgets('removing an open section prunes it and emits', (tester) async {
      Set<String>? emitted;
      await tester.pumpWidget(
        host(
          FossAccordion(
            initialValue: const {'b'},
            onValueChanged: (v) => emitted = v,
            children: _items,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The parent drops item 'b'; the uncontrolled open set must shed it.
      const without = <FossAccordionItem>[
        FossAccordionItem(value: 'a', title: Text('Title A'), child: Text('A')),
        FossAccordionItem(value: 'c', title: Text('Title C'), child: Text('C')),
      ];
      await tester.pumpWidget(
        host(
          FossAccordion(
            initialValue: const {'b'},
            onValueChanged: (v) => emitted = v,
            children: without,
          ),
        ),
      );
      await tester.pump();

      expect(emitted, isEmpty);
    });
  });

  group('controlled', () {
    testWidgets('renders value and does not own state', (tester) async {
      Set<String>? emitted;
      await tester.pumpWidget(
        host(
          FossAccordion(
            value: const {'a'},
            onValueChanged: (v) => emitted = v,
            children: _items,
          ),
        ),
      );
      await tester.pumpAndSettle();
      _expectOpen(tester, 'Title A', open: true);

      await tester.tap(find.text('Title A'));
      await tester.pumpAndSettle();
      // The callback reports the next set, but the parent still owns it, so the
      // rendered state does not change until value does.
      expect(emitted, isEmpty);
      _expectOpen(tester, 'Title A', open: true);
    });
  });

  group('keyboard', () {
    testWidgets('Space toggles the focused header', (tester) async {
      Set<String>? emitted;
      await tester.pumpWidget(
        host(
          FossAccordion(onValueChanged: (v) => emitted = v, children: _items),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(emitted, {'a'});
    });

    testWidgets('Arrow Down moves focus to the next header', (tester) async {
      Set<String>? emitted;
      await tester.pumpWidget(
        host(
          FossAccordion(onValueChanged: (v) => emitted = v, children: _items),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(emitted, {'b'});
    });

    testWidgets('End jumps to the last header', (tester) async {
      Set<String>? emitted;
      await tester.pumpWidget(
        host(
          FossAccordion(onValueChanged: (v) => emitted = v, children: _items),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(emitted, {'c'});
    });

    testWidgets('focus ring shows on keyboard focus only', (tester) async {
      await tester.pumpWidget(host(const FossAccordion(children: _items)));
      expect(_hasRing(tester), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_hasRing(tester), isTrue);
    });

    testWidgets('focus ring follows arrow navigation between headers', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FossAccordion(children: _items)));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      // The ring must stay on the newly focused header, not vanish in the
      // highlight-off / highlight-on crossover.
      expect(_hasRing(tester), isTrue);
    });
  });

  group('disabled item', () {
    const items = <FossAccordionItem>[
      FossAccordionItem(value: 'a', title: Text('A'), child: Text('pa')),
      FossAccordionItem(
        value: 'b',
        title: Text('B'),
        child: Text('pb'),
        enabled: false,
      ),
      FossAccordionItem(value: 'c', title: Text('C'), child: Text('pc')),
    ];

    testWidgets('ignores taps', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        host(FossAccordion(onValueChanged: (_) => calls++, children: items)),
      );
      await tester.tap(find.text('B'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(calls, 0);
    });

    testWidgets('keyboard skips it', (tester) async {
      Set<String>? emitted;
      await tester.pumpWidget(
        host(
          FossAccordion(onValueChanged: (v) => emitted = v, children: items),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      // Focus starts on 'a'; Arrow Down skips disabled 'b' and lands on 'c'.
      expect(emitted, {'c'});
    });
  });

  group('adaptivity', () {
    testWidgets('RTL mirrors the header: chevron leads the title', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: FossAccordion(children: _items),
          ),
        ),
      );
      final chevron = _chevronCenter(tester).dx;
      final title = tester.getCenter(find.text('Title A')).dx;
      expect(chevron, lessThan(title));
    });

    testWidgets('textScale 2.0 grows the header without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: FossAccordion(children: _items),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Title A'), findsOneWidget);
    });

    testWidgets('reduced motion opens instantly', (tester) async {
      await tester.pumpWidget(
        host(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: FossAccordion(children: _items),
          ),
        ),
      );
      await tester.tap(find.text('Title A'));
      await tester.pump();
      // With animations disabled the panel is at full height after one frame.
      final align = tester.widget<Align>(
        find
            .ancestor(of: find.text('Panel A'), matching: find.byType(Align))
            .first,
      );
      expect(align.heightFactor, 1.0);
    });
  });

  group('style override', () {
    testWidgets('recolors the divider via the resolver', (tester) async {
      await tester.pumpWidget(
        host(
          const FossAccordion(
            initialValue: {'a'},
            style: FossAccordionStyle(
              dividerColor: Color(0xFFFF0000),
              chevronColor: Color(0xFF00FF00),
              titleTextStyle: TextStyle(fontSize: 20),
              panelTextStyle: TextStyle(fontSize: 10),
              headerPadding: EdgeInsets.all(20),
              panelPadding: EdgeInsets.all(10),
            ),
            children: _items,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final hasOverriddenDivider = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((b) => b.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.border != null)
          .any(
            (d) =>
                (d.border! as Border).bottom.color == const Color(0xFFFF0000),
          );
      expect(hasOverriddenDivider, isTrue);
    });
  });

  group('lifecycle', () {
    testWidgets('rebuilding without the focused item drops its focus', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FossAccordion(children: _items)));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_hasRing(tester), isTrue);

      await tester.pumpWidget(
        host(
          const FossAccordion(
            children: [
              FossAccordionItem(
                value: 'b',
                title: Text('Title B'),
                child: Text('Panel B'),
              ),
              FossAccordionItem(
                value: 'c',
                title: Text('Title C'),
                child: Text('Panel C'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Title A'), findsNothing);
      expect(_hasRing(tester), isFalse);
    });
  });

  group('dark theme', () {
    testWidgets('resolves the dark roles without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FossThemeData.dark.toThemeData(),
          home: const Scaffold(
            body: Center(child: FossAccordion(children: _items)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Title A'), findsOneWidget);
    });
  });

  group('item', () {
    test('holds its fields and defaults enabled to true', () {
      // Runtime values force a non-const build, unlike the const item lists
      // the widget tests use.
      final title = Text('t${1 + 1}');
      final item = FossAccordionItem(
        value: 'id${1 + 1}',
        title: title,
        child: const SizedBox.shrink(),
      );
      expect(item.value, 'id2');
      expect(item.title, same(title));
      expect(item.enabled, isTrue);
    });
  });
}
