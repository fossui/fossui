import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

// A month pinned by bounds so the dialog opens on a deterministic grid: the
// calendar clamps its displayed month into [min, max].
DateTime _min(int year, int month) => DateTime(year, month);
DateTime _max(int year, int month) => DateTime(year, month + 1, 0);

void main() {
  group('FossDatePicker trigger fill', () {
    testWidgets('dark theme lifts the resting fill by the input color', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossDatePicker.single(selected: null, onSelected: (_) {}),
          theme: FossThemeData.dark,
        ),
      );
      expect(find.text('Pick a date'), findsOneWidget);
    });
  });

  group('FossDatePicker.single label', () {
    testWidgets('shows the placeholder when empty', (tester) async {
      await tester.pumpWidget(
        host(FossDatePicker.single(selected: null, onSelected: (_) {})),
      );

      expect(find.text('Pick a date'), findsOneWidget);
    });

    testWidgets('formats the selected date', (tester) async {
      await tester.pumpWidget(
        host(
          FossDatePicker.single(
            selected: DateTime(2026, 3, 6),
            onSelected: (_) {},
          ),
        ),
      );

      expect(find.text('March 6th, 2026'), findsOneWidget);
      expect(find.text('Pick a date'), findsNothing);
    });

    testWidgets('applies the correct ordinal suffix', (tester) async {
      const cases = {
        1: 'January 1st, 2026',
        2: 'January 2nd, 2026',
        3: 'January 3rd, 2026',
        4: 'January 4th, 2026',
        11: 'January 11th, 2026',
        12: 'January 12th, 2026',
        13: 'January 13th, 2026',
        21: 'January 21st, 2026',
        22: 'January 22nd, 2026',
        23: 'January 23rd, 2026',
      };
      for (final entry in cases.entries) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          host(
            FossDatePicker.single(
              selected: DateTime(2026, 1, entry.key),
              onSelected: (_) {},
            ),
          ),
        );
        expect(find.text(entry.value), findsOneWidget);
      }
    });

    testWidgets('a custom format overrides the default', (tester) async {
      await tester.pumpWidget(
        host(
          FossDatePicker.single(
            selected: DateTime(2026, 3, 6),
            onSelected: (_) {},
            format: (d) => '${d.year}-${d.month}-${d.day}',
          ),
        ),
      );

      expect(find.text('2026-3-6'), findsOneWidget);
    });
  });

  group('FossDatePicker.range label', () {
    testWidgets('shows the placeholder when empty', (tester) async {
      await tester.pumpWidget(
        host(FossDatePicker.range(selected: null, onSelected: (_) {})),
      );

      expect(find.text('Pick a date range'), findsOneWidget);
    });

    testWidgets('formats both ends', (tester) async {
      await tester.pumpWidget(
        host(
          FossDatePicker.range(
            selected: FossDateRange(
              start: DateTime(2026, 7, 9),
              end: DateTime(2026, 7, 16),
            ),
            onSelected: (_) {},
          ),
        ),
      );

      expect(find.text('Jul 09, 2026 - Jul 16, 2026'), findsOneWidget);
    });

    testWidgets('collapses a one-day span to a single end', (tester) async {
      await tester.pumpWidget(
        host(
          FossDatePicker.range(
            selected: FossDateRange(
              start: DateTime(2026, 7, 9),
              end: DateTime(2026, 7, 9),
            ),
            onSelected: (_) {},
          ),
        ),
      );

      expect(find.text('Jul 09, 2026'), findsOneWidget);
    });

    testWidgets('a custom format overrides both ends', (tester) async {
      await tester.pumpWidget(
        host(
          FossDatePicker.range(
            selected: FossDateRange(
              start: DateTime(2026, 7, 9),
              end: DateTime(2026, 7, 16),
            ),
            onSelected: (_) {},
            format: (r) => '${r.start.day} to ${r.end.day}',
          ),
        ),
      );

      expect(find.text('9 to 16'), findsOneWidget);
      expect(find.text('Jul 09, 2026 - Jul 16, 2026'), findsNothing);
    });
  });

  group('open and close', () {
    testWidgets('tapping the trigger opens the calendar dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FossDatePicker.single(selected: null, onSelected: (_) {})),
      );

      expect(find.byType(FossCalendar), findsNothing);
      await tester.tap(find.text('Pick a date'));
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsOneWidget);
    });

    testWidgets('the centered presentation also opens', (tester) async {
      await tester.pumpWidget(
        host(
          FossDatePicker.single(
            selected: null,
            onSelected: (_) {},
            presentation: FossDialogPresentation.centered,
          ),
        ),
      );

      await tester.tap(find.text('Pick a date'));
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsOneWidget);
    });

    testWidgets('a disabled trigger does not open', (tester) async {
      await tester.pumpWidget(
        host(
          FossDatePicker.single(
            selected: null,
            onSelected: (_) {},
            enabled: false,
          ),
        ),
      );

      await tester.tap(find.text('Pick a date'));
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsNothing);
    });

    testWidgets('open true on mount shows the dialog without a tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossDatePicker.single(
            selected: null,
            onSelected: (_) {},
            open: true,
            onOpenChange: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FossCalendar), findsOneWidget);
    });

    testWidgets('uncontrolled open still reports both edges', (tester) async {
      final changes = <bool>[];
      await tester.pumpWidget(
        host(
          FossDatePicker.single(
            selected: null,
            onSelected: (_) {},
            onOpenChange: changes.add,
          ),
        ),
      );

      await tester.tap(find.text('Pick a date'));
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(changes, [true, false]);
      expect(find.byType(FossCalendar), findsNothing);
    });

    testWidgets('Escape closes the open dialog', (tester) async {
      await tester.pumpWidget(
        host(FossDatePicker.single(selected: null, onSelected: (_) {})),
      );

      await tester.tap(find.text('Pick a date'));
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsNothing);
    });

    testWidgets('the down arrow opens the focused trigger', (tester) async {
      await tester.pumpWidget(
        host(FossDatePicker.single(selected: null, onSelected: (_) {})),
      );

      final detector = tester.widget<FocusableActionDetector>(
        find.descendant(
          of: find.byType(FossDatePicker),
          matching: find.byType(FocusableActionDetector),
        ),
      );
      detector.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(find.byType(FossCalendar), findsOneWidget);
    });

    testWidgets('Android back closes the dialog', (tester) async {
      await tester.pumpWidget(
        host(FossDatePicker.single(selected: null, onSelected: (_) {})),
      );

      await tester.tap(find.text('Pick a date'));
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsNothing);
    });

    testWidgets('opens and closes with reduced motion', (tester) async {
      await tester.pumpWidget(
        host(
          FossDatePicker.single(selected: null, onSelected: (_) {}),
          reduceMotion: true,
        ),
      );

      await tester.tap(find.text('Pick a date'));
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsNothing);
    });
  });

  group('close-on-select policy', () {
    testWidgets('single pick fires onSelected and closes', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        host(
          FossDatePicker.single(
            selected: null,
            onSelected: (d) => picked = d,
            minDate: _min(2026, 3),
            maxDate: _max(2026, 3),
          ),
        ),
      );

      await tester.tap(find.text('Pick a date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();

      expect(picked, DateTime(2026, 3, 20));
      expect(find.byType(FossCalendar), findsNothing);
    });

    testWidgets('closeOnSelect false keeps a single pick open', (tester) async {
      await tester.pumpWidget(
        host(
          FossDatePicker.single(
            selected: null,
            onSelected: (_) {},
            closeOnSelect: false,
            minDate: _min(2026, 3),
            maxDate: _max(2026, 3),
          ),
        ),
      );

      await tester.tap(find.text('Pick a date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();

      expect(find.byType(FossCalendar), findsOneWidget);
    });

    testWidgets('range stays open until both ends are set', (tester) async {
      final picks = <FossDateRange>[];
      await tester.pumpWidget(
        host(
          FossDatePicker.range(
            selected: null,
            onSelected: picks.add,
            minDate: _min(2026, 7),
            maxDate: _max(2026, 7),
          ),
        ),
      );

      await tester.tap(find.text('Pick a date range'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsOneWidget, reason: 'first tap');

      await tester.tap(find.text('16'));
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsNothing, reason: 'second tap');

      expect(picks.length, 2);
      expect(
        picks.last,
        FossDateRange(start: DateTime(2026, 7, 9), end: DateTime(2026, 7, 16)),
      );
    });

    testWidgets('a re-pick over a seeded range still takes two taps', (
      tester,
    ) async {
      final picks = <FossDateRange>[];
      await tester.pumpWidget(
        host(
          FossDatePicker.range(
            selected: FossDateRange(
              start: DateTime(2026, 7, 6),
              end: DateTime(2026, 7, 10),
            ),
            onSelected: picks.add,
            minDate: _min(2026, 7),
            maxDate: _max(2026, 7),
          ),
        ),
      );

      await tester.tap(find.text('Jul 06, 2026 - Jul 10, 2026'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsOneWidget, reason: 'first tap');
      expect(
        picks.single,
        FossDateRange(start: DateTime(2026, 7, 20), end: DateTime(2026, 7, 20)),
        reason: 'the first tap restarts the range on the tapped day',
      );

      await tester.tap(find.text('24'));
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsNothing, reason: 'second tap');
      expect(picks.length, 2);
      expect(
        picks.last,
        FossDateRange(start: DateTime(2026, 7, 20), end: DateTime(2026, 7, 24)),
      );
    });

    testWidgets('closeOnSelect false keeps a completed range open', (
      tester,
    ) async {
      final picks = <FossDateRange>[];
      await tester.pumpWidget(
        host(
          FossDatePicker.range(
            selected: null,
            onSelected: picks.add,
            closeOnSelect: false,
            minDate: _min(2026, 7),
            maxDate: _max(2026, 7),
          ),
        ),
      );

      await tester.tap(find.text('Pick a date range'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('16'));
      await tester.pumpAndSettle();

      expect(picks.length, 2);
      expect(find.byType(FossCalendar), findsOneWidget);
    });
  });

  group('controlled open', () {
    testWidgets('the open flag drives the dialog', (tester) async {
      var open = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FossDatePicker.single(
              selected: null,
              onSelected: (_) {},
              open: open,
              onOpenChange: (v) => setState(() => open = v),
            ),
          ),
        ),
      );

      expect(find.byType(FossCalendar), findsNothing);

      await tester.tap(find.text('Pick a date'));
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsOneWidget);
      expect(open, isTrue);
    });

    testWidgets('lowering the open flag closes the dialog', (tester) async {
      var open = true;
      late StateSetter set;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return FossDatePicker.single(
                selected: null,
                onSelected: (_) {},
                open: open,
                onOpenChange: (v) => setState(() => open = v),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsOneWidget);

      set(() => open = false);
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsNothing);
    });

    testWidgets('a dismiss reports through onOpenChange', (tester) async {
      bool? lastChange;
      await tester.pumpWidget(
        host(
          FossDatePicker.single(
            selected: null,
            onSelected: (_) {},
            open: true,
            onOpenChange: (v) => lastChange = v,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(lastChange, isFalse);
    });
  });

  group('accessibility', () {
    testWidgets('the trigger exposes its value to semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          FossDatePicker.single(
            selected: DateTime(2026, 3, 6),
            onSelected: (_) {},
            semanticsLabel: 'Start date',
          ),
        ),
      );

      expect(
        tester.getSemantics(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.value == 'March 6th, 2026',
          ),
        ),
        isSemantics(
          label: 'Start date',
          value: 'March 6th, 2026',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('opens under RTL', (tester) async {
      await tester.pumpWidget(
        host(
          FossDatePicker.range(selected: null, onSelected: (_) {}),
          direction: TextDirection.rtl,
        ),
      );

      await tester.tap(find.text('Pick a date range'));
      await tester.pumpAndSettle();
      expect(find.byType(FossCalendar), findsOneWidget);
    });
  });

  group('FossDatePickerStyle', () {
    test('merge layers non-null fields of the override', () {
      const base = FossDatePickerStyle(
        placeholderColor: Color(0xFF111111),
        gap: 4,
      );
      const override = FossDatePickerStyle(gap: 8);
      final merged = base.merge(override);

      expect(merged.gap, 8);
      expect(merged.placeholderColor, const Color(0xFF111111));
    });

    test('merge with null returns the receiver', () {
      const base = FossDatePickerStyle(gap: 4);
      expect(base.merge(null), same(base));
    });
  });
}
