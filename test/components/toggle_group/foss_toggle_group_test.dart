import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

const _items = [
  FossToggleGroupItem(value: 'left', child: Text('Left')),
  FossToggleGroupItem(value: 'center', child: Text('Center')),
  FossToggleGroupItem(value: 'right', child: Text('Right')),
];

bool _hasFocusRing(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .any(
      (c) => c.foregroundPainter?.runtimeType.toString() == '_FocusRingPainter',
    );

void main() {
  group('FossToggleGroup.single', () {
    testWidgets('selecting an item reports its value', (tester) async {
      String? value = 'left';
      await tester.pumpWidget(
        host(
          FossToggleGroup.single(
            value: value,
            onChanged: (v) => value = v,
            children: _items,
          ),
        ),
      );

      await tester.tap(find.text('Center'));
      expect(value, 'center');
    });

    testWidgets('tapping the active item clears to null', (tester) async {
      String? value = 'left';
      await tester.pumpWidget(
        host(
          FossToggleGroup.single(
            value: value,
            onChanged: (v) => value = v,
            children: _items,
          ),
        ),
      );

      await tester.tap(find.text('Left'));
      expect(value, isNull);
    });

    testWidgets('renders one toggle per item', (tester) async {
      await tester.pumpWidget(
        host(
          FossToggleGroup.single(
            value: null,
            onChanged: (_) {},
            children: _items,
          ),
        ),
      );

      expect(find.byType(FossToggle), findsNWidgets(3));
    });
  });

  group('FossToggleGroup.multiple', () {
    testWidgets('adds a value to the set', (tester) async {
      var value = <String>{'left'};
      await tester.pumpWidget(
        host(
          FossToggleGroup.multiple(
            value: value,
            onChanged: (v) => value = v,
            children: _items,
          ),
        ),
      );

      await tester.tap(find.text('Right'));
      expect(value, {'left', 'right'});
    });

    testWidgets('removes a selected value from the set', (tester) async {
      var value = <String>{'left', 'right'};
      await tester.pumpWidget(
        host(
          FossToggleGroup.multiple(
            value: value,
            onChanged: (v) => value = v,
            children: _items,
          ),
        ),
      );

      await tester.tap(find.text('Left'));
      expect(value, {'right'});
    });
  });

  group('FossToggleGroup disable', () {
    testWidgets('group enabled false blocks every item', (tester) async {
      var changed = false;
      await tester.pumpWidget(
        host(
          FossToggleGroup.single(
            value: null,
            enabled: false,
            onChanged: (_) => changed = true,
            children: _items,
          ),
        ),
      );

      await tester.tap(find.text('Center'), warnIfMissed: false);
      expect(changed, isFalse);
    });

    testWidgets('item enabled false blocks just that item', (tester) async {
      String? value;
      await tester.pumpWidget(
        host(
          FossToggleGroup.single(
            value: null,
            onChanged: (v) => value = v,
            children: const [
              FossToggleGroupItem(value: 'left', child: Text('Left')),
              FossToggleGroupItem(
                value: 'center',
                enabled: false,
                child: Text('Center'),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Center'), warnIfMissed: false);
      expect(value, isNull);

      await tester.tap(find.text('Left'));
      expect(value, 'left');
    });

    testWidgets('a disabled item keeps its place in a multiple set', (
      tester,
    ) async {
      var value = {'left', 'center'};
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FossToggleGroup.multiple(
              value: value,
              onChanged: (v) => setState(() => value = v),
              children: const [
                FossToggleGroupItem(value: 'left', child: Text('Left')),
                FossToggleGroupItem(
                  value: 'center',
                  enabled: false,
                  child: Text('Center'),
                ),
                FossToggleGroupItem(value: 'right', child: Text('Right')),
              ],
            ),
          ),
        ),
      );

      // The disabled item is already selected. It cannot be tapped out, and
      // toggling a sibling must not drop it from the set.
      await tester.tap(find.text('Center'), warnIfMissed: false);
      await tester.pump();
      expect(value, {'left', 'center'});

      await tester.tap(find.text('Right'));
      await tester.pump();
      expect(value, {'left', 'center', 'right'});

      await tester.tap(find.text('Left'));
      await tester.pump();
      expect(value, {'center', 'right'});
    });
  });

  group('FossToggleGroup layout', () {
    testWidgets('outline variant renders joined items', (tester) async {
      await tester.pumpWidget(
        host(
          FossToggleGroup.single(
            value: 'left',
            variant: FossToggleVariant.outline,
            onChanged: (_) {},
            children: _items,
          ),
        ),
      );

      expect(find.byType(FossToggle), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('outline lays out inside an unbounded scroll view', (
      tester,
    ) async {
      // A horizontal joined bar stretches its cells; inside a ListView the
      // cross axis is unbounded, so it must bound itself rather than crash.
      await tester.pumpWidget(
        host(
          ListView(
            children: [
              FossToggleGroup.single(
                value: 'left',
                variant: FossToggleVariant.outline,
                onChanged: (_) {},
                children: _items,
              ),
              FossToggleGroup.multiple(
                value: const {'left'},
                variant: FossToggleVariant.outline,
                orientation: Axis.vertical,
                onChanged: (_) {},
                children: _items,
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('vertical orientation lays out without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossToggleGroup.multiple(
            value: const {'left'},
            orientation: Axis.vertical,
            variant: FossToggleVariant.outline,
            onChanged: (_) {},
            children: _items,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('the focus ring answers the keyboard, not the pointer', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossToggleGroup.single(
            value: null,
            variant: FossToggleVariant.outline,
            onChanged: (_) {},
            children: _items,
          ),
        ),
      );

      await tester.tap(find.text('Center'));
      await tester.pump();
      expect(_hasFocusRing(tester), isFalse, reason: 'a tap shows no ring');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_hasFocusRing(tester), isTrue);
    });

    testWidgets('the inner seams are one pixel wide', (tester) async {
      await tester.pumpWidget(
        host(
          FossToggleGroup.single(
            value: 'left',
            variant: FossToggleVariant.outline,
            onChanged: (_) {},
            children: _items,
          ),
        ),
      );

      // Three joined cells leave two seams, and each is a hairline: any wider
      // and the bar reads as separate buttons.
      final seams = tester
          .widgetList<SizedBox>(
            find.descendant(
              of: find.byType(FossToggleGroup),
              matching: find.byType(SizedBox),
            ),
          )
          .where((b) => b.width == 1)
          .toList();
      expect(seams.length, 2);
      for (final seam in seams) {
        expect(seam.height, isNull, reason: 'a seam stretches to the bar');
      }
    });

    testWidgets('a vertical bar seams on the cross axis', (tester) async {
      await tester.pumpWidget(
        host(
          FossToggleGroup.single(
            value: 'left',
            variant: FossToggleVariant.outline,
            orientation: Axis.vertical,
            onChanged: (_) {},
            children: _items,
          ),
        ),
      );

      final seams = tester
          .widgetList<SizedBox>(
            find.descendant(
              of: find.byType(FossToggleGroup),
              matching: find.byType(SizedBox),
            ),
          )
          .where((b) => b.height == 1)
          .toList();
      expect(seams.length, 2);
      expect(seams.every((b) => b.width == null), isTrue);
    });

    testWidgets('RTL mirrors the bar without changing its frame', (
      tester,
    ) async {
      Rect frameOf(WidgetTester t) =>
          t.getRect(find.byType(FossToggleGroup).first);

      await tester.pumpWidget(
        host(
          FossToggleGroup.single(
            value: 'left',
            variant: FossToggleVariant.outline,
            onChanged: (_) {},
            children: _items,
          ),
        ),
      );
      final ltrFrame = frameOf(tester);
      final ltrFirst = tester.getCenter(find.text('Left')).dx;
      final ltrLast = tester.getCenter(find.text('Right')).dx;
      expect(ltrFirst, lessThan(ltrLast));

      await tester.pumpWidget(
        host(
          FossToggleGroup.single(
            value: 'left',
            variant: FossToggleVariant.outline,
            onChanged: (_) {},
            children: _items,
          ),
          direction: TextDirection.rtl,
        ),
      );

      expect(frameOf(tester).size, ltrFrame.size);
      expect(
        tester.getCenter(find.text('Left')).dx,
        greaterThan(tester.getCenter(find.text('Right')).dx),
        reason: 'the first item sits at the right end under RTL',
      );
    });

    testWidgets('a lone item rounds every corner', (tester) async {
      // A single child is both first and last, taking the full-radius path.
      // ignore: prefer_const_declarations
      final v = 'only';
      await tester.pumpWidget(
        host(
          FossToggleGroup.single(
            value: v,
            variant: FossToggleVariant.outline,
            onChanged: (_) {},
            children: [FossToggleGroupItem(value: v, child: const Text('One'))],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the outline frame repaints when selection changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossToggleGroup.single(
            value: 'left',
            variant: FossToggleVariant.outline,
            onChanged: (_) {},
            children: _items,
          ),
        ),
      );
      // A rebuild with a new value hands the frame painter a fresh instance,
      // exercising its repaint check.
      await tester.pumpWidget(
        host(
          FossToggleGroup.single(
            value: 'right',
            variant: FossToggleVariant.outline,
            onChanged: (_) {},
            children: _items,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
