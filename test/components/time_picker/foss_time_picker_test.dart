import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

/// The wheel column carrying [label] on its adjustable semantics node.
Finder _column(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
);

/// The expanded flag the trigger publishes. Read off the widget rather than the
/// semantics node, because an open modal blocks the tree beneath it.
bool _triggerExpanded(WidgetTester tester) =>
    tester
        .widget<Semantics>(
          find
              .descendant(
                of: find.byType(FossTimePicker),
                matching: find.byType(Semantics),
              )
              .first,
        )
        .properties
        .expanded ??
    false;

/// Opens the modal from the trigger and settles the route transition.
Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byType(FossTimePicker));
  await tester.pumpAndSettle();
}

/// Focuses the column carrying [label] and presses [key] on it.
Future<void> _pressOn(
  WidgetTester tester,
  String label,
  LogicalKeyboardKey key, {
  bool settle = true,
}) async {
  final wheel = find.descendant(
    of: _column(label),
    matching: find.byType(ListWheelScrollView),
  );
  Focus.of(tester.element(wheel)).requestFocus();
  await tester.pump();
  await tester.sendKeyEvent(key);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  group('FossTimeOfDay', () {
    test('compares by position in the day', () {
      const early = FossTimeOfDay(hour: 9, minute: 30);
      const late = FossTimeOfDay(hour: 17, minute: 5);
      expect(early.compareTo(late), isNegative);
      expect(late.compareTo(early), isPositive);
      expect(early.compareTo(const FossTimeOfDay(hour: 9, minute: 30)), 0);
    });

    test('orders across the hour boundary', () {
      const before = FossTimeOfDay(hour: 9, minute: 59);
      const after = FossTimeOfDay(hour: 10, minute: 0);
      expect(before.compareTo(after), isNegative);
    });

    test('equality and hashCode cover both fields', () {
      const a = FossTimeOfDay(hour: 9, minute: 30);
      const b = FossTimeOfDay(hour: 9, minute: 30);
      const c = FossTimeOfDay(hour: 9, minute: 31);
      const d = FossTimeOfDay(hour: 21, minute: 30);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a, isNot(d));
      expect(a == a, isTrue);
    });

    test('rejects out-of-range fields', () {
      expect(() => FossTimeOfDay(hour: 24, minute: 0), throwsAssertionError);
      expect(() => FossTimeOfDay(hour: -1, minute: 0), throwsAssertionError);
      expect(() => FossTimeOfDay(hour: 0, minute: 60), throwsAssertionError);
      expect(() => FossTimeOfDay(hour: 0, minute: -1), throwsAssertionError);
    });

    test('toString names both fields', () {
      expect(
        const FossTimeOfDay(hour: 9, minute: 30).toString(),
        contains('9:30'),
      );
    });
  });

  group('FossTimePickerStyle', () {
    test('merge lays every non-null field of the argument on top', () {
      const base = FossTimePickerStyle(
        placeholderColor: Color(0xFF111111),
        gap: 4,
        itemExtent: 40,
        visibleItemCount: 3,
        highlightColor: Color(0xFF222222),
      );
      const over = FossTimePickerStyle(gap: 8, visibleItemCount: 5);
      final merged = base.merge(over);

      expect(merged.gap, 8);
      expect(merged.visibleItemCount, 5);
      expect(merged.placeholderColor, const Color(0xFF111111));
      expect(merged.itemExtent, 40);
      expect(merged.highlightColor, const Color(0xFF222222));
    });

    test('merge with null returns the receiver', () {
      const base = FossTimePickerStyle(gap: 4);
      expect(identical(base.merge(null), base), isTrue);
    });

    test('rejects an even or tiny visible count and a zero extent', () {
      expect(
        () => FossTimePickerStyle(visibleItemCount: 4),
        throwsAssertionError,
      );
      expect(
        () => FossTimePickerStyle(visibleItemCount: 1),
        throwsAssertionError,
      );
      expect(() => FossTimePickerStyle(itemExtent: 0), throwsAssertionError);
    });
  });

  group('FossTimePicker minuteStep', () {
    test('rejects a step that does not divide 60', () {
      expect(
        () => FossTimePicker(value: null, onChanged: (_) {}, minuteStep: 7),
        throwsAssertionError,
      );
      expect(
        () => FossTimePicker(value: null, onChanged: (_) {}, minuteStep: 0),
        throwsAssertionError,
      );
    });
  });

  group('FossTimePicker trigger label', () {
    testWidgets('shows the placeholder when empty', (tester) async {
      await tester.pumpWidget(
        host(FossTimePicker(value: null, onChanged: (_) {})),
      );
      expect(find.text('Pick a time'), findsOneWidget);
    });

    testWidgets('formats a 12-hour value', (tester) async {
      const cases = <(FossTimeOfDay, String)>[
        (FossTimeOfDay(hour: 9, minute: 30), '9:30 AM'),
        (FossTimeOfDay(hour: 21, minute: 30), '9:30 PM'),
        (FossTimeOfDay(hour: 0, minute: 5), '12:05 AM'),
        (FossTimeOfDay(hour: 12, minute: 0), '12:00 PM'),
      ];
      for (final (time, label) in cases) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          host(FossTimePicker(value: time, onChanged: (_) {})),
        );
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('formats a 24-hour value', (tester) async {
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 21, minute: 30),
            onChanged: (_) {},
            use24HourFormat: true,
          ),
        ),
      );
      expect(find.text('21:30'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 9, minute: 5),
            onChanged: (_) {},
            use24HourFormat: true,
          ),
        ),
      );
      expect(find.text('09:05'), findsOneWidget);
    });

    testWidgets('falls back to the platform hour format', (tester) async {
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 21, minute: 30),
            onChanged: (_) {},
          ),
          alwaysUse24HourFormat: true,
        ),
      );
      expect(find.text('21:30'), findsOneWidget);
    });

    testWidgets('an explicit flag beats the platform setting', (tester) async {
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 21, minute: 30),
            onChanged: (_) {},
            use24HourFormat: false,
          ),
          alwaysUse24HourFormat: true,
        ),
      );
      expect(find.text('9:30 PM'), findsOneWidget);
    });

    testWidgets('a custom format overrides the default', (tester) async {
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 9, minute: 30),
            onChanged: (_) {},
            format: (t) => 'at ${t.hour}h${t.minute}',
          ),
        ),
      );
      expect(find.text('at 9h30'), findsOneWidget);
    });

    testWidgets('renders in the dark theme', (tester) async {
      await tester.pumpWidget(
        host(
          FossTimePicker(value: null, onChanged: (_) {}),
          theme: FossThemeData.dark,
        ),
      );
      expect(find.text('Pick a time'), findsOneWidget);
    });
  });

  group('FossTimePicker opening', () {
    testWidgets('a tap opens the modal', (tester) async {
      await tester.pumpWidget(
        host(FossTimePicker(value: null, onChanged: (_) {})),
      );
      await _open(tester);

      expect(find.text('Set'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byType(ListWheelScrollView), findsNWidgets(3));
    });

    testWidgets('the down arrow opens the modal', (tester) async {
      await tester.pumpWidget(
        host(FossTimePicker(value: null, onChanged: (_) {})),
      );
      Focus.of(tester.element(find.text('Pick a time'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(find.text('Set'), findsOneWidget);
    });

    testWidgets('a disabled trigger never opens', (tester) async {
      await tester.pumpWidget(
        host(
          FossTimePicker(value: null, onChanged: (_) {}, enabled: false),
        ),
      );
      await tester.tap(find.byType(FossTimePicker));
      await tester.pumpAndSettle();

      expect(find.text('Set'), findsNothing);
    });

    testWidgets('24-hour mode drops the period column', (tester) async {
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: null,
            onChanged: (_) {},
            use24HourFormat: true,
          ),
        ),
      );
      await _open(tester);

      expect(find.byType(ListWheelScrollView), findsNWidgets(2));
      expect(find.text('AM'), findsNothing);
      expect(find.text('PM'), findsNothing);
    });

    testWidgets('the modal title reuses the placeholder', (tester) async {
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: null,
            onChanged: (_) {},
            placeholder: 'Start time',
          ),
        ),
      );
      await _open(tester);

      // Once in the trigger, once as the modal title.
      expect(find.text('Start time'), findsNWidgets(2));
    });

    testWidgets('presents as a centered card when asked', (tester) async {
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: null,
            onChanged: (_) {},
            presentation: FossDialogPresentation.centered,
          ),
        ),
      );
      await _open(tester);

      expect(find.text('Set'), findsOneWidget);
    });
  });

  group('FossTimePicker commit', () {
    testWidgets('confirm reports the draft exactly once', (tester) async {
      final reported = <FossTimeOfDay>[];
      await tester.pumpWidget(
        host(FossTimePicker(value: null, onChanged: reported.add)),
      );
      await _open(tester);
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();

      expect(reported, [const FossTimeOfDay(hour: 0, minute: 0)]);
      expect(find.text('Set'), findsNothing);
    });

    testWidgets('cancel discards the draft', (tester) async {
      final reported = <FossTimeOfDay>[];
      await tester.pumpWidget(
        host(FossTimePicker(value: null, onChanged: reported.add)),
      );
      await _open(tester);
      await _pressOn(tester, 'Hour', LogicalKeyboardKey.arrowDown);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(reported, isEmpty);
      expect(find.text('Set'), findsNothing);
    });

    testWidgets('the barrier discards the draft', (tester) async {
      final reported = <FossTimeOfDay>[];
      await tester.pumpWidget(
        host(FossTimePicker(value: null, onChanged: reported.add)),
      );
      await _open(tester);
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(reported, isEmpty);
      expect(find.text('Set'), findsNothing);
    });

    testWidgets('scrolling a wheel does not report', (tester) async {
      final reported = <FossTimeOfDay>[];
      await tester.pumpWidget(
        host(FossTimePicker(value: null, onChanged: reported.add)),
      );
      await _open(tester);
      await tester.drag(
        find.byType(ListWheelScrollView).first,
        const Offset(0, -80),
      );
      await tester.pumpAndSettle();

      expect(reported, isEmpty);
    });

    testWidgets('the wheels open on the committed value', (tester) async {
      final reported = <FossTimeOfDay>[];
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 21, minute: 30),
            onChanged: reported.add,
          ),
        ),
      );
      await _open(tester);
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();

      expect(reported, [const FossTimeOfDay(hour: 21, minute: 30)]);
    });

    testWidgets('the period column moves the hour by twelve', (tester) async {
      final reported = <FossTimeOfDay>[];
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 9, minute: 30),
            onChanged: reported.add,
          ),
        ),
      );
      await _open(tester);
      await _pressOn(tester, 'Period', LogicalKeyboardKey.arrowDown);
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();

      expect(reported, [const FossTimeOfDay(hour: 21, minute: 30)]);
    });

    testWidgets('the hour wheel rolls the period as it wraps', (tester) async {
      Future<FossTimeOfDay?> stepFrom(
        FossTimeOfDay start,
        LogicalKeyboardKey key,
      ) async {
        FossTimeOfDay? reported;
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          host(
            FossTimePicker(
              value: start,
              onChanged: (time) => reported = time,
            ),
          ),
        );
        await _open(tester);
        await _pressOn(tester, 'Hour', key);
        await tester.tap(find.text('Set'));
        await tester.pumpAndSettle();
        return reported;
      }

      // 11 AM steps forward into noon, not back to midnight.
      expect(
        await stepFrom(
          const FossTimeOfDay(hour: 11, minute: 30),
          LogicalKeyboardKey.arrowDown,
        ),
        const FossTimeOfDay(hour: 12, minute: 30),
      );
      // Midnight steps back into the previous evening.
      expect(
        await stepFrom(
          const FossTimeOfDay(hour: 0, minute: 0),
          LogicalKeyboardKey.arrowUp,
        ),
        const FossTimeOfDay(hour: 23, minute: 0),
      );
    });

    testWidgets('the period wheel follows the roll on screen', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 11, minute: 30),
            onChanged: (_) {},
          ),
        ),
      );
      await _open(tester);
      expect(
        tester.getSemantics(_column('Period')),
        isSemantics(value: 'AM'),
      );

      await _pressOn(tester, 'Hour', LogicalKeyboardKey.arrowDown);
      expect(
        tester.getSemantics(_column('Period')),
        isSemantics(value: 'PM'),
      );
      // The wheel itself moved, not just the label.
      final period = tester.widget<ListWheelScrollView>(
        find.descendant(
          of: _column('Period'),
          matching: find.byType(ListWheelScrollView),
        ),
      );
      expect(
        period.controller,
        isA<FixedExtentScrollController>().having(
          (c) => c.selectedItem,
          'selectedItem',
          1,
        ),
      );
      handle.dispose();
    });

    testWidgets('changing the period leaves the other wheels alone', (
      tester,
    ) async {
      int itemOf(String label) {
        final wheel = tester.widget<ListWheelScrollView>(
          find.descendant(
            of: _column(label),
            matching: find.byType(ListWheelScrollView),
          ),
        );
        final controller = wheel.controller;
        return controller is FixedExtentScrollController
            ? controller.selectedItem
            : -1;
      }

      final reported = <FossTimeOfDay>[];
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 9, minute: 0),
            onChanged: reported.add,
            minuteStep: 30,
            minTime: const FossTimeOfDay(hour: 9, minute: 0),
            maxTime: const FossTimeOfDay(hour: 17, minute: 0),
          ),
        ),
      );
      await _open(tester);
      expect(itemOf('Hour'), 9);
      expect(itemOf('Minute'), 0);

      await _pressOn(tester, 'Period', LogicalKeyboardKey.arrowDown);

      expect(itemOf('Hour'), 9);
      expect(itemOf('Minute'), 0);
      expect(itemOf('Period'), 1);

      // The same move by drag, which is how a phone actually does it.
      await _pressOn(tester, 'Period', LogicalKeyboardKey.arrowUp);
      expect(itemOf('Period'), 0);

      await tester.drag(
        find.descendant(
          of: _column('Period'),
          matching: find.byType(ListWheelScrollView),
        ),
        const Offset(0, -36),
      );
      await tester.pumpAndSettle();

      expect(itemOf('Period'), 1);
      expect(itemOf('Hour'), 9);
      expect(itemOf('Minute'), 0);
    });

    testWidgets('a 24-hour wheel wraps without a period', (tester) async {
      final reported = <FossTimeOfDay>[];
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 0, minute: 0),
            onChanged: reported.add,
            use24HourFormat: true,
          ),
        ),
      );
      await _open(tester);
      await _pressOn(tester, 'Hour', LogicalKeyboardKey.arrowUp);
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();

      expect(reported, [const FossTimeOfDay(hour: 23, minute: 0)]);
    });

    testWidgets('an arrow step moves one row', (tester) async {
      final reported = <FossTimeOfDay>[];
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 9, minute: 30),
            onChanged: reported.add,
          ),
        ),
      );
      await _open(tester);
      await _pressOn(tester, 'Hour', LogicalKeyboardKey.arrowDown);
      await _pressOn(tester, 'Minute', LogicalKeyboardKey.arrowUp);
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();

      expect(reported, [const FossTimeOfDay(hour: 10, minute: 29)]);
    });
  });

  group('FossTimePicker minuteStep', () {
    testWidgets('builds the column from the step', (tester) async {
      await tester.pumpWidget(
        host(
          FossTimePicker(value: null, onChanged: (_) {}, minuteStep: 15),
        ),
      );
      await _open(tester);

      // Four rows do not fill the window, so the column is finite and opens on
      // its first entry: 00, 15, 30 are on screen and 45 is below the fold.
      expect(find.text('15'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('01'), findsNothing);
    });

    testWidgets('a column too short to fill the window does not loop', (
      tester,
    ) async {
      // Two rows behind five slots would show each value more than once.
      await tester.pumpWidget(
        host(FossTimePicker(value: null, onChanged: (_) {}, minuteStep: 30)),
      );
      await _open(tester);

      expect(find.text('30'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
      // The hour column is long enough, so it still wraps.
      expect(find.text('11'), findsOneWidget);
    });

    testWidgets('a step of one offers every minute', (tester) async {
      await tester.pumpWidget(
        host(FossTimePicker(value: null, onChanged: (_) {})),
      );
      await _open(tester);

      expect(find.text('01'), findsWidgets);
    });

    testWidgets('an off-grid value reports back unchanged', (tester) async {
      final reported = <FossTimeOfDay>[];
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 9, minute: 7),
            onChanged: reported.add,
            minuteStep: 15,
          ),
        ),
      );
      expect(find.text('9:07 AM'), findsOneWidget);

      await _open(tester);
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();

      expect(reported, [const FossTimeOfDay(hour: 9, minute: 7)]);
    });

    testWidgets('an off-grid value snaps when any wheel moves', (tester) async {
      // The minute wheel is parked on the nearest step, so holding the off-grid
      // minute past an hour change would commit a time never shown.
      for (final column in const ['Hour', 'Period']) {
        final reported = <FossTimeOfDay>[];
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          host(
            FossTimePicker(
              value: const FossTimeOfDay(hour: 9, minute: 7),
              onChanged: reported.add,
              minuteStep: 15,
            ),
          ),
        );
        await _open(tester);
        await _pressOn(tester, column, LogicalKeyboardKey.arrowDown);
        await tester.tap(find.text('Set'));
        await tester.pumpAndSettle();

        expect(
          reported.single.minute,
          0,
          reason: 'the $column wheel should snap the parked minute to its step',
        );
      }
    });

    testWidgets('an off-grid value snaps on the first minute step', (
      tester,
    ) async {
      final reported = <FossTimeOfDay>[];
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 9, minute: 7),
            onChanged: reported.add,
            minuteStep: 15,
          ),
        ),
      );
      await _open(tester);
      await _pressOn(tester, 'Minute', LogicalKeyboardKey.arrowDown);
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();

      expect(reported, [const FossTimeOfDay(hour: 9, minute: 15)]);
    });
  });

  group('FossTimePicker bounds', () {
    testWidgets('an unset picker opens on the first allowed entry', (
      tester,
    ) async {
      final reported = <FossTimeOfDay>[];
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: null,
            onChanged: reported.add,
            minTime: const FossTimeOfDay(hour: 9, minute: 30),
          ),
        ),
      );
      await _open(tester);
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();

      expect(reported, [const FossTimeOfDay(hour: 9, minute: 30)]);
    });

    testWidgets('a predicate skips the times it blocks', (tester) async {
      final reported = <FossTimeOfDay>[];
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: null,
            onChanged: reported.add,
            minuteStep: 30,
            isTimeEnabled: (t) => t.hour >= 8 && t.minute == 30,
          ),
        ),
      );
      await _open(tester);
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();

      expect(reported, [const FossTimeOfDay(hour: 8, minute: 30)]);
    });

    testWidgets('confirm disables while the draft is blocked', (tester) async {
      final reported = <FossTimeOfDay>[];
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: null,
            onChanged: reported.add,
            isTimeEnabled: (_) => false,
          ),
        ),
      );
      await _open(tester);
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();

      expect(reported, isEmpty);
      // Still open: the disabled action swallowed the tap.
      expect(find.text('Set'), findsOneWidget);
    });

    testWidgets('confirm re-enables once the draft clears the bound', (
      tester,
    ) async {
      final reported = <FossTimeOfDay>[];
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 9, minute: 0),
            onChanged: reported.add,
            minuteStep: 30,
            maxTime: const FossTimeOfDay(hour: 9, minute: 0),
          ),
        ),
      );
      await _open(tester);
      await _pressOn(tester, 'Minute', LogicalKeyboardKey.arrowDown);
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();

      expect(reported, isEmpty);

      await _pressOn(tester, 'Minute', LogicalKeyboardKey.arrowUp);
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();

      expect(reported, [const FossTimeOfDay(hour: 9, minute: 0)]);
    });

    testWidgets('a bounded column stops at its ends', (tester) async {
      final reported = <FossTimeOfDay>[];
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 0, minute: 0),
            onChanged: reported.add,
            minuteStep: 30,
            minTime: const FossTimeOfDay(hour: 0, minute: 0),
          ),
        ),
      );
      await _open(tester);
      await _pressOn(tester, 'Minute', LogicalKeyboardKey.arrowUp);
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();

      // The finite column clamps rather than wrapping to 30.
      expect(reported, [const FossTimeOfDay(hour: 0, minute: 0)]);
    });

    testWidgets('an unbounded column wraps past its ends', (tester) async {
      final reported = <FossTimeOfDay>[];
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 0, minute: 0),
            onChanged: reported.add,
          ),
        ),
      );
      await _open(tester);
      await _pressOn(tester, 'Minute', LogicalKeyboardKey.arrowUp);
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();

      expect(reported, [const FossTimeOfDay(hour: 0, minute: 59)]);
    });
  });

  group('FossTimePicker open state', () {
    testWidgets('onOpenChange fires on open and on close', (tester) async {
      final changes = <bool>[];
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: null,
            onChanged: (_) {},
            onOpenChange: changes.add,
          ),
        ),
      );
      await _open(tester);
      expect(changes, [true]);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(changes, [true, false]);
    });

    testWidgets('the controlled path drives the route', (tester) async {
      Widget build({required bool open}) => host(
        FossTimePicker(
          value: null,
          onChanged: (_) {},
          open: open,
          onOpenChange: (_) {},
        ),
      );

      await tester.pumpWidget(build(open: false));
      expect(find.text('Set'), findsNothing);

      await tester.pumpWidget(build(open: true));
      await tester.pumpAndSettle();
      expect(find.text('Set'), findsOneWidget);

      await tester.pumpWidget(build(open: false));
      await tester.pumpAndSettle();
      expect(find.text('Set'), findsNothing);
    });

    testWidgets('a controlled trigger tap does not open on its own', (
      tester,
    ) async {
      final changes = <bool>[];
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: null,
            onChanged: (_) {},
            open: false,
            onOpenChange: changes.add,
          ),
        ),
      );
      await tester.tap(find.byType(FossTimePicker));
      await tester.pumpAndSettle();

      expect(changes, [true]);
      expect(find.text('Set'), findsNothing);
    });

    testWidgets('opens on the first frame when built already open', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: null,
            onChanged: (_) {},
            open: true,
            onOpenChange: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set'), findsOneWidget);
    });
  });

  group('FossTimePicker accessibility', () {
    testWidgets('the trigger is a button carrying the value and its state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 9, minute: 30),
            onChanged: (_) {},
            semanticsLabel: 'Appointment time',
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(FossTimePicker)),
        isSemantics(
          isButton: true,
          isEnabled: true,
          label: 'Appointment time',
          value: '9:30 AM',
          isExpanded: false,
        ),
      );
      expect(_triggerExpanded(tester), isFalse);

      await _open(tester);
      expect(_triggerExpanded(tester), isTrue);
      handle.dispose();
    });

    testWidgets('each column is a labelled adjustable', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 9, minute: 30),
            onChanged: (_) {},
          ),
        ),
      );
      await _open(tester);

      for (final entry in const {
        'Hour': '9',
        'Minute': '30',
        'Period': 'AM',
      }.entries) {
        expect(
          tester.getSemantics(_column(entry.key)),
          isSemantics(
            label: entry.key,
            value: entry.value,
            hasIncreaseAction: true,
            hasDecreaseAction: true,
          ),
        );
      }
      handle.dispose();
    });

    testWidgets('the adjustable actions step the column', (tester) async {
      final handle = tester.ensureSemantics();
      final reported = <FossTimeOfDay>[];
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: const FossTimeOfDay(hour: 9, minute: 30),
            onChanged: reported.add,
          ),
        ),
      );
      await _open(tester);

      tester.semantics.performAction(
        find.semantics.byLabel('Hour'),
        SemanticsAction.increase,
      );
      await tester.pumpAndSettle();
      tester.semantics.performAction(
        find.semantics.byLabel('Minute'),
        SemanticsAction.decrease,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();

      expect(reported, [const FossTimeOfDay(hour: 10, minute: 29)]);
      handle.dispose();
    });

    testWidgets('reduced motion jumps instead of animating', (tester) async {
      // Zero-duration pumps advance frames without advancing the clock, so a
      // jump lands immediately while an animated step has made no progress.
      Future<String?> stepAndRead({required bool reduceMotion}) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          host(
            FossTimePicker(
              value: const FossTimeOfDay(hour: 9, minute: 30),
              onChanged: (_) {},
            ),
            reduceMotion: reduceMotion,
          ),
        );
        await _open(tester);
        await _pressOn(
          tester,
          'Hour',
          LogicalKeyboardKey.arrowDown,
          settle: false,
        );
        await tester.pump();
        return tester.getSemantics(_column('Hour')).value;
      }

      final handle = tester.ensureSemantics();
      expect(await stepAndRead(reduceMotion: true), '10');
      expect(await stepAndRead(reduceMotion: false), '9');
      handle.dispose();
      await tester.pumpAndSettle();
    });

    testWidgets('RTL orders the columns start to end', (tester) async {
      Future<double> centerOf(String label) async =>
          tester.getCenter(_column(label)).dx;

      await tester.pumpWidget(
        host(FossTimePicker(value: null, onChanged: (_) {})),
      );
      await _open(tester);
      expect(await centerOf('Hour'), lessThan(await centerOf('Period')));

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        host(
          FossTimePicker(value: null, onChanged: (_) {}),
          direction: TextDirection.rtl,
        ),
      );
      await _open(tester);
      expect(await centerOf('Hour'), greaterThan(await centerOf('Period')));
    });

    testWidgets('a doubled text scale grows the sheet without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossTimePicker(value: null, onChanged: (_) {}),
          textScale: 2,
        ),
      );
      await _open(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(ListWheelScrollView), findsNWidgets(3));
    });
  });

  group('FossTimePicker style', () {
    testWidgets('a per-instance style reaches the trigger and the wheels', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossTimePicker(
            value: null,
            onChanged: (_) {},
            style: const FossTimePickerStyle(
              placeholderColor: Color(0xFFAA0000),
              gap: 12,
              itemExtent: 48,
              visibleItemCount: 3,
              highlightColor: Color(0xFF00AA00),
            ),
          ),
        ),
      );

      final label = tester.widget<Text>(find.text('Pick a time'));
      expect(label.style?.color, const Color(0xFFAA0000));

      await _open(tester);
      final wheel = tester.widget<ListWheelScrollView>(
        find.byType(ListWheelScrollView).first,
      );
      expect(wheel.itemExtent, 48);
    });
  });
}
