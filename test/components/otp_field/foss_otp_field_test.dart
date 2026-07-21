import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

// Every slot draws its chrome with a RoundedSuperellipseBorder; the border
// color tells rest (input) from active (ring) from error (destructive).
List<Color> _borderColors(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(FossOtpField),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((b) => b.decoration)
    .whereType<ShapeDecoration>()
    .map((d) => d.shape)
    .whereType<RoundedSuperellipseBorder>()
    .map((s) => s.side.color)
    .toList();

Future<void> _enter(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump();
}

void main() {
  final ring = FossThemeData.light.colors.ring;
  final destructive = FossThemeData.light.colors.destructive;

  group('typing', () {
    testWidgets('fills slots and reports the code', (tester) async {
      String? seen;
      await tester.pumpWidget(
        host(FossOtpField(length: 6, onChanged: (v) => seen = v)),
      );

      await _enter(tester, '12');

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(seen, '12');
    });

    testWidgets('backspace clears the last slot and retreats', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        host(FossOtpField(length: 6, onChanged: values.add)),
      );

      await _enter(tester, '12');
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(values.last, '1');
      expect(find.text('2'), findsNothing);
    });

    testWidgets('arrow left retreats the caret', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        host(FossOtpField(length: 6, onChanged: values.add)),
      );

      await _enter(tester, '12');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      // Backspace now clears the slot before the moved caret, not the last one.
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(values.last, '2');
      expect(find.text('1'), findsNothing);
    });

    testWidgets('onCompleted fires when the row fills', (tester) async {
      final completed = <String>[];
      await tester.pumpWidget(
        host(FossOtpField(length: 4, onCompleted: completed.add)),
      );

      await _enter(tester, '123');
      expect(completed, isEmpty);

      await _enter(tester, '1234');
      expect(completed, ['1234']);
    });
  });

  group('validation', () {
    testWidgets('numeric drops letters', (tester) async {
      await tester.pumpWidget(host(const FossOtpField(length: 6)));

      await _enter(tester, '1a2b3');

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('a'), findsNothing);
    });

    testWidgets('alphanumeric keeps letters and digits', (tester) async {
      await tester.pumpWidget(
        host(
          const FossOtpField(
            length: 6,
            validation: FossOtpValidation.alphanumeric,
          ),
        ),
      );

      await _enter(tester, 'a1');

      expect(find.text('a'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('none accepts any character', (tester) async {
      await tester.pumpWidget(
        host(
          const FossOtpField(length: 6, validation: FossOtpValidation.none),
        ),
      );

      await _enter(tester, r'#$');

      expect(find.text('#'), findsOneWidget);
      expect(find.text(r'$'), findsOneWidget);
    });

    testWidgets('length caps the value at the slot count', (tester) async {
      String? seen;
      await tester.pumpWidget(
        host(FossOtpField(length: 4, onChanged: (v) => seen = v)),
      );

      await _enter(tester, '123456');

      expect(seen, '1234');
    });
  });

  group('masking', () {
    testWidgets('obscure hides the characters', (tester) async {
      await tester.pumpWidget(
        host(const FossOtpField(length: 6, obscure: true)),
      );

      await _enter(tester, '12');

      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
    });
  });

  group('grouping', () {
    testWidgets('a valid group split widens the row', (tester) async {
      await tester.pumpWidget(
        host(const FossOtpField(length: 6, groups: [3, 3])),
      );
      final grouped = tester.getSize(find.byType(Row)).width;

      await tester.pumpWidget(host(const FossOtpField(length: 6)));
      final plain = tester.getSize(find.byType(Row)).width;

      expect(grouped, greaterThan(plain));
    });

    testWidgets('a group sum that does not match length is a no-op', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const FossOtpField(length: 6, groups: [2, 2])),
      );
      final bad = tester.getSize(find.byType(Row)).width;

      await tester.pumpWidget(host(const FossOtpField(length: 6)));
      final plain = tester.getSize(find.byType(Row)).width;

      expect(bad, plain);
    });
  });

  group('states', () {
    testWidgets('the active slot borders with the ring color', (tester) async {
      await tester.pumpWidget(host(const FossOtpField(length: 4)));

      expect(_borderColors(tester).where((c) => c == ring), isEmpty);

      await tester.tap(find.byType(FossOtpField));
      await tester.pump();

      expect(_borderColors(tester).where((c) => c == ring), hasLength(1));
    });

    testWidgets('a tap outside releases focus', (tester) async {
      await tester.pumpWidget(host(const FossOtpField(length: 4)));

      await tester.tap(find.byType(FossOtpField));
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);

      await tester.tapAt(const Offset(5, 5));
      await tester.pump();

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
    });

    testWidgets('a full focused row keeps one active slot', (tester) async {
      await tester.pumpWidget(
        host(const FossOtpField(length: 4, value: '1234', autofocus: true)),
      );
      await tester.pump();

      expect(_borderColors(tester).where((c) => c == ring), hasLength(1));
    });

    testWidgets('error recolors the slot borders off the resting input', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FossOtpField(length: 4, error: true)));
      final errored = _borderColors(tester);

      await tester.pumpWidget(host(const FossOtpField(length: 4)));
      final rest = _borderColors(tester);

      expect(errored, isNotEmpty);
      expect(errored.first, isNot(rest.first));
      expect(errored.any((c) => c == ring), isFalse);
      // The error accent derives from the destructive role (alpha aside).
      final c = errored.first;
      final d = destructive;
      expect(c.r == d.r && c.g == d.g && c.b == d.b, isTrue);
    });

    testWidgets('disabled is read-only and ignores taps', (tester) async {
      String? seen;
      await tester.pumpWidget(
        host(
          FossOtpField(length: 4, enabled: false, onChanged: (v) => seen = v),
        ),
      );

      await tester.tap(find.byType(FossOtpField), warnIfMissed: false);
      await tester.pump();

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).readOnly,
        isTrue,
      );
      expect(seen, isNull);
    });
  });

  group('coverage', () {
    testWidgets('the large size renders bigger slots', (tester) async {
      Future<double> rowWidth(FossOtpFieldSize size) async {
        await tester.pumpWidget(host(FossOtpField(length: 4, size: size)));
        return tester.getSize(find.byType(Row)).width;
      }

      final md = await rowWidth(FossOtpFieldSize.md);
      final lg = await rowWidth(FossOtpFieldSize.lg);

      expect(lg, greaterThan(md));
    });

    testWidgets('renders under a dark theme', (tester) async {
      await tester.pumpWidget(
        host(
          FossTheme(
            data: FossThemeData.dark,
            child: const FossOtpField(length: 4, value: '12'),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('a style override reaches the slots', (tester) async {
      await tester.pumpWidget(
        host(
          const FossOtpField(
            length: 4,
            style: FossOtpFieldStyle(slotSize: 60),
          ),
        ),
      );

      final slot = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .firstWhere(
            (b) => b.width == 60 && b.height == 60,
          );
      expect(slot.width, 60);
    });

    testWidgets('drops focus when disabled mid-edit', (tester) async {
      await tester.pumpWidget(host(const FossOtpField(length: 4)));
      await tester.tap(find.byType(FossOtpField));
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);

      await tester.pumpWidget(
        host(const FossOtpField(length: 4, enabled: false)),
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

  group('controlled', () {
    testWidgets('reflects an external value change', (tester) async {
      await tester.pumpWidget(host(const FossOtpField(length: 6, value: '12')));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.pumpWidget(host(const FossOtpField(length: 6, value: '34')));
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('a value longer than length is clamped', (tester) async {
      await tester.pumpWidget(
        host(const FossOtpField(length: 4, value: '123456')),
      );

      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsNothing);
      expect(find.text('6'), findsNothing);
    });

    testWidgets('user completion after a controlled reset still fires', (
      tester,
    ) async {
      final completed = <String>[];
      await tester.pumpWidget(
        host(
          FossOtpField(length: 4, value: '1234', onCompleted: completed.add),
        ),
      );
      // The parent resets the row to a partial value.
      await tester.pumpWidget(
        host(FossOtpField(length: 4, value: '12', onCompleted: completed.add)),
      );
      await tester.pump();
      completed.clear();

      // Typing the row back to full fires onCompleted: the completeness guard
      // was resynced by the controlled write, so it is still authoritative.
      await tester.enterText(find.byType(EditableText), '1234');
      await tester.pump();

      expect(completed, ['1234']);
    });
  });

  group('accessibility', () {
    testWidgets('exposes a single labelled field', (tester) async {
      await tester.pumpWidget(
        host(const FossOtpField(length: 6, semanticsLabel: 'Code')),
      );

      expect(find.bySemanticsLabel('Code'), findsOneWidget);
    });

    testWidgets('renders in RTL', (tester) async {
      await tester.pumpWidget(
        host(
          const FossOtpField(length: 6, value: '12'),
          direction: TextDirection.rtl,
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('a large text scale grows the slots', (tester) async {
      Future<double> heightAt(double scale) async {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: host(const FossOtpField(length: 4)),
          ),
        );
        return tester.getSize(find.byType(Row)).height;
      }

      final small = await heightAt(1);
      final large = await heightAt(2);

      expect(large, greaterThan(small));
    });

    testWidgets('reduced motion stops the caret blink', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: host(const FossOtpField(length: 4, autofocus: true)),
        ),
      );

      // A blinking caret would schedule frames forever and hang pumpAndSettle;
      // reduced motion holds it steady, so the tree settles.
      await tester.pumpAndSettle();
    });
  });
}
