import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

Finder _decoration = find.descendant(
  of: find.byType(FossNumberField),
  matching: find.byType(DecoratedBox),
);

Color _borderColor(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(_decoration.first);
  final shape = (box.decoration as ShapeDecoration).shape;
  return (shape as RoundedSuperellipseBorder).side.color;
}

Future<void> _focus(WidgetTester tester) async {
  await tester.tap(find.byType(EditableText));
  await tester.pump();
}

void main() {
  group('stepping', () {
    testWidgets('increment button raises the value by step', (tester) async {
      num? seen;
      await tester.pumpWidget(
        host(FossNumberField(value: 3, onChanged: (v) => seen = v)),
      );

      await tester.tap(find.bySemanticsLabel('Increment'));
      await tester.pump();

      expect(seen, 4);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('decrement button lowers the value by step', (tester) async {
      num? seen;
      await tester.pumpWidget(
        host(FossNumberField(value: 3, step: 2, onChanged: (v) => seen = v)),
      );

      await tester.tap(find.bySemanticsLabel('Decrement'));
      await tester.pump();

      expect(seen, 1);
    });

    testWidgets('steps from the lower bound when empty', (tester) async {
      num? seen;
      await tester.pumpWidget(
        host(FossNumberField(min: 5, onChanged: (v) => seen = v)),
      );

      await tester.tap(find.bySemanticsLabel('Increment'));
      await tester.pump();

      expect(seen, 6);
    });

    testWidgets('a fractional step does not accumulate float drift', (
      tester,
    ) async {
      num? seen;
      await tester.pumpWidget(
        host(
          FossNumberField(
            initialValue: 0,
            step: 0.1,
            onChanged: (v) => seen = v,
          ),
        ),
      );

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.bySemanticsLabel('Increment'));
        await tester.pump();
      }

      expect(seen, 0.3);
      expect(find.text('0.3'), findsOneWidget);
      expect(find.textContaining('0.30000'), findsNothing);
    });
  });

  group('clamp', () {
    testWidgets('increment stops at max and disables the stepper', (
      tester,
    ) async {
      num? seen;
      await tester.pumpWidget(
        host(
          FossNumberField(value: 10, max: 10, onChanged: (v) => seen = v),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Increment'));
      await tester.pump();

      expect(seen, isNull);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('decrement stops at min', (tester) async {
      num? seen;
      await tester.pumpWidget(
        host(FossNumberField(value: 0, min: 0, onChanged: (v) => seen = v)),
      );

      await tester.tap(find.bySemanticsLabel('Decrement'));
      await tester.pump();

      expect(seen, isNull);
    });

    testWidgets('a typed out-of-range value snaps in on blur', (tester) async {
      final values = <num?>[];
      await tester.pumpWidget(
        host(FossNumberField(max: 10, onChanged: values.add)),
      );

      await tester.enterText(find.byType(EditableText), '99');
      await tester.pump();
      expect(values.last, 99);

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      expect(values.last, 10);
      expect(find.text('10'), findsOneWidget);
    });
  });

  group('typing', () {
    testWidgets('reports the parsed value through onChanged', (tester) async {
      num? seen;
      await tester.pumpWidget(
        host(FossNumberField(onChanged: (v) => seen = v)),
      );

      await tester.enterText(find.byType(EditableText), '42');

      expect(seen, 42);
    });

    testWidgets('reports null when the text does not parse', (tester) async {
      final values = <num?>[];
      await tester.pumpWidget(
        host(FossNumberField(initialValue: 1, onChanged: values.add)),
      );

      await tester.enterText(find.byType(EditableText), '');

      expect(values.last, isNull);
    });

    testWidgets('rejects non-numeric characters on entry', (tester) async {
      await tester.pumpWidget(host(FossNumberField()));

      await tester.enterText(find.byType(EditableText), 'abc');

      expect(find.text('abc'), findsNothing);
    });
  });

  group('keyboard', () {
    testWidgets('arrow keys step by step', (tester) async {
      num? seen;
      await tester.pumpWidget(
        host(FossNumberField(value: 3, onChanged: (v) => seen = v)),
      );
      await _focus(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(seen, 4);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(seen, 3);
    });

    testWidgets('page keys step by largeStep', (tester) async {
      num? seen;
      await tester.pumpWidget(
        host(
          FossNumberField(
            value: 3,
            largeStep: 10,
            onChanged: (v) => seen = v,
          ),
        ),
      );
      await _focus(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pump();

      expect(seen, 13);
    });
  });

  group('format and parse', () {
    testWidgets('the default renders a plain decimal string', (tester) async {
      await tester.pumpWidget(host(FossNumberField(initialValue: 7)));

      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('custom format and parse round-trip', (tester) async {
      num? seen;
      await tester.pumpWidget(
        host(
          FossNumberField(
            initialValue: 5,
            format: (v) => '\$$v',
            parse: (s) => num.tryParse(s.replaceAll(r'$', '')),
            onChanged: (v) => seen = v,
          ),
        ),
      );

      expect(find.text(r'$5'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Increment'));
      await tester.pump();

      expect(seen, 6);
      expect(find.text(r'$6'), findsOneWidget);
    });
  });

  group('states', () {
    testWidgets('disabled ignores taps and is read-only', (tester) async {
      num? seen;
      await tester.pumpWidget(
        host(
          FossNumberField(value: 3, enabled: false, onChanged: (v) => seen = v),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Increment'), warnIfMissed: false);
      await tester.pump();

      expect(seen, isNull);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).readOnly,
        isTrue,
      );
    });

    testWidgets('error recolors the border to destructive', (tester) async {
      await tester.pumpWidget(host(FossNumberField(error: true)));
      final errorBorder = _borderColor(tester);

      await tester.pumpWidget(host(FossNumberField()));
      final restBorder = _borderColor(tester);

      expect(errorBorder, isNot(restBorder));
    });

    testWidgets('placeholder shows while empty and hides once filled', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FossNumberField(placeholder: 'Qty')),
      );
      expect(find.text('Qty'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), '2');
      await tester.pump();

      expect(find.text('Qty'), findsNothing);
    });
  });

  group('accessibility', () {
    testWidgets('the increase action steps up', (tester) async {
      num? seen;
      await tester.pumpWidget(
        host(FossNumberField(value: 3, onChanged: (v) => seen = v)),
      );

      final handle = tester.ensureSemantics();
      final node = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.value == '3',
      );
      tester.widget<Semantics>(node.first).properties.onIncrease!();
      await tester.pump();

      expect(seen, 4);
      handle.dispose();
    });

    testWidgets('RTL keeps decrement and increment working', (tester) async {
      num? seen;
      await tester.pumpWidget(
        host(
          FossNumberField(value: 3, onChanged: (v) => seen = v),
          direction: TextDirection.rtl,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Decrement'));
      await tester.pump();

      expect(seen, 2);
    });

    testWidgets('a large text scale grows the box', (tester) async {
      Future<double> heightAt(double scale) async {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: host(FossNumberField(initialValue: 1)),
          ),
        );
        return tester.getSize(find.byType(EditableText).first).height;
      }

      final small = await heightAt(1);
      final large = await heightAt(2);

      expect(large, greaterThan(small));
    });
  });

  group('controlled', () {
    testWidgets('reflects an external value change', (tester) async {
      await tester.pumpWidget(host(FossNumberField(value: 3)));
      expect(find.text('3'), findsOneWidget);

      await tester.pumpWidget(host(FossNumberField(value: 8)));
      await tester.pump();

      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('reports an out-of-range value back clamped', (tester) async {
      num? value = 2;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FossNumberField(
              value: value,
              max: 10,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText), '99');
      // Let the controlled parent rebuild with the out-of-range 99 first, so
      // the field clamps its internal value before the blur commit runs.
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      expect(value, 10);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('drops focus when disabled mid-edit', (tester) async {
      await tester.pumpWidget(host(const FossNumberField(value: 3)));
      await _focus(tester);
      expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);

      await tester.pumpWidget(
        host(const FossNumberField(value: 3, enabled: false)),
      );
      await tester.pump();

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
    });
  });

  group('coverage', () {
    testWidgets('page down steps down by largeStep', (tester) async {
      num? seen;
      await tester.pumpWidget(
        host(
          FossNumberField(value: 30, largeStep: 10, onChanged: (v) => seen = v),
        ),
      );
      await _focus(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();

      expect(seen, 20);
    });

    testWidgets('the decrease action steps down', (tester) async {
      num? seen;
      await tester.pumpWidget(
        host(FossNumberField(value: 3, onChanged: (v) => seen = v)),
      );

      final handle = tester.ensureSemantics();
      final node = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.value == '3',
      );
      tester.widget<Semantics>(node.first).properties.onDecrease!();
      await tester.pump();

      expect(seen, 2);
      handle.dispose();
    });

    testWidgets('tapping outside commits and clamps', (tester) async {
      num? seen;
      await tester.pumpWidget(
        host(FossNumberField(max: 10, onChanged: (v) => seen = v)),
      );

      await tester.enterText(find.byType(EditableText), '99');
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();

      expect(seen, 10);
    });

    testWidgets('the default format trims a whole double', (tester) async {
      await tester.pumpWidget(host(const FossNumberField(initialValue: 2.5)));
      expect(find.text('2.5'), findsOneWidget);

      await tester.pumpWidget(host(const SizedBox()));
      await tester.pumpWidget(host(const FossNumberField(initialValue: 4.0)));
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('a hovered stepper fills with the accent color', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FossNumberField(value: 3)));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      final accent = FossThemeData.light.colors.accent;
      bool anyAccentFill() =>
          tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).any((b) {
            final d = b.decoration;
            return d is ShapeDecoration && d.color == accent;
          });

      await gesture.moveTo(
        tester.getCenter(find.bySemanticsLabel('Increment')),
      );
      await tester.pump();
      expect(anyAccentFill(), isTrue);

      await gesture.moveTo(
        tester.getCenter(find.bySemanticsLabel('Decrement')),
      );
      await tester.pump();
      expect(anyAccentFill(), isTrue);

      await gesture.moveTo(const Offset(-100, -100));
      await tester.pump();
      expect(anyAccentFill(), isFalse);
    });

    testWidgets('a style override reaches the box', (tester) async {
      await tester.pumpWidget(
        host(
          const FossNumberField(
            value: 3,
            style: FossNumberFieldStyle(borderRadius: 20),
          ),
        ),
      );

      final box = tester.widget<DecoratedBox>(_decoration.first);
      final shape =
          (box.decoration as ShapeDecoration).shape
              as RoundedSuperellipseBorder;
      expect(shape.borderRadius.resolve(TextDirection.ltr).topLeft.x, 20);
    });
  });
}
