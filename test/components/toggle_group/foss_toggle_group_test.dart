import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

const _items = [
  FossToggleGroupItem(value: 'left', child: Text('Left')),
  FossToggleGroupItem(value: 'center', child: Text('Center')),
  FossToggleGroupItem(value: 'right', child: Text('Right')),
];

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
  });
}
