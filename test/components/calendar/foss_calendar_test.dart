import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

// March 2026 starts on a Sunday, so a Monday-first grid leads with six February
// days (23 to 28) and trails with five April days (1 to 5). Numbers 6 to 22 and
// 29 to 31 are therefore unique to March and safe to target by text.
final _march = DateTime(2026, 3);

bool? _selected(WidgetTester t, String label) => t
    .getSemantics(find.bySemanticsLabel(label))
    .getSemanticsData()
    .flagsCollection
    .isSelected
    .toBoolOrNull();

bool _enabled(WidgetTester t, String label) =>
    t
        .getSemantics(find.bySemanticsLabel(label))
        .getSemanticsData()
        .flagsCollection
        .isEnabled
        .toBoolOrNull() ??
    false;

bool _hasRing(WidgetTester t) => t
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .any(
      (c) => c.foregroundPainter?.runtimeType.toString() == '_DayRingPainter',
    );

void main() {
  group('render', () {
    testWidgets('shows the caption, weekday header, and month days', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (_) {},
            initialMonth: _march,
          ),
        ),
      );
      expect(find.text('March 2026'), findsOneWidget);
      expect(find.text('Mo'), findsOneWidget);
      expect(find.text('Su'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('shows outside days when showOutsideDays is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (_) {},
            initialMonth: _march,
          ),
        ),
      );
      // April 5 pads the trailing week alongside March 5.
      expect(find.text('5'), findsNWidgets(2));
    });

    testWidgets('hides outside days when showOutsideDays is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (_) {},
            initialMonth: _march,
            showOutsideDays: false,
          ),
        ),
      );
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('caption spans the grid width, not the parent', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 400,
            child: FossCalendar.single(selected: null, onSelected: (_) {}),
          ),
        ),
      );

      // The caption arrows must sit at the grid edges, not the parent edges:
      // seven 40px columns wide, regardless of the wider parent.
      final prev = find.bySemanticsLabel('Previous month');
      final next = find.bySemanticsLabel('Next month');
      final left = tester.getTopLeft(prev).dx;
      final right = tester.getTopRight(next).dx;
      expect(right - left, 7 * 40.0);
    });
  });

  group('single selection', () {
    testWidgets('tap reports the calendar day', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (d) => picked = d,
            initialMonth: _march,
          ),
        ),
      );
      await tester.tap(find.text('15'));
      expect(picked, DateTime(2026, 3, 15));
    });

    testWidgets('selected day exposes the selected flag', (tester) async {
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: DateTime(2026, 3, 15),
            onSelected: (_) {},
            initialMonth: _march,
          ),
        ),
      );
      expect(_selected(tester, 'March 15, 2026'), isTrue);
      expect(_selected(tester, 'March 16, 2026'), isFalse);
    });
  });

  group('multiple selection', () {
    testWidgets('taps toggle days in and out of the set', (tester) async {
      var current = <DateTime>{};
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FossCalendar.multiple(
              selected: current,
              onSelected: (s) => setState(() => current = s),
              initialMonth: _march,
            ),
          ),
        ),
      );
      await tester.tap(find.text('10'));
      await tester.pump();
      await tester.tap(find.text('20'));
      await tester.pump();
      expect(current, {DateTime(2026, 3, 10), DateTime(2026, 3, 20)});

      await tester.tap(find.text('10'));
      await tester.pump();
      expect(current, {DateTime(2026, 3, 20)});
    });
  });

  group('range selection', () {
    testWidgets('two taps set the span; a middle day reads selected', (
      tester,
    ) async {
      FossDateRange? current;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FossCalendar.range(
              selected: current,
              onSelected: (r) => setState(() => current = r),
              initialMonth: _march,
            ),
          ),
        ),
      );
      await tester.tap(find.text('10'));
      await tester.pump();
      expect(
        current,
        FossDateRange(start: DateTime(2026, 3, 10), end: DateTime(2026, 3, 10)),
      );

      await tester.tap(find.text('20'));
      await tester.pump();
      expect(
        current,
        FossDateRange(start: DateTime(2026, 3, 10), end: DateTime(2026, 3, 20)),
      );
      expect(_selected(tester, 'March 15, 2026'), isTrue);
    });

    testWidgets('a reversed second tap orders the span', (tester) async {
      FossDateRange? current;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FossCalendar.range(
              selected: current,
              onSelected: (r) => setState(() => current = r),
              initialMonth: _march,
            ),
          ),
        ),
      );
      await tester.tap(find.text('20'));
      await tester.pump();
      await tester.tap(find.text('10'));
      await tester.pump();
      expect(
        current,
        FossDateRange(start: DateTime(2026, 3, 10), end: DateTime(2026, 3, 20)),
      );
    });

    testWidgets('a third tap restarts the range', (tester) async {
      FossDateRange? current;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => FossCalendar.range(
              selected: current,
              onSelected: (r) => setState(() => current = r),
              initialMonth: _march,
            ),
          ),
        ),
      );
      await tester.tap(find.text('10'));
      await tester.pump();
      await tester.tap(find.text('20'));
      await tester.pump();
      await tester.tap(find.text('6'));
      await tester.pump();
      expect(
        current,
        FossDateRange(start: DateTime(2026, 3, 6), end: DateTime(2026, 3, 6)),
      );
    });
  });

  group('bounds and disable', () {
    testWidgets('a day before minDate is disabled and inert', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (d) => picked = d,
            initialMonth: _march,
            minDate: DateTime(2026, 3, 10),
          ),
        ),
      );
      expect(_enabled(tester, 'March 6, 2026'), isFalse);
      await tester.tap(find.text('6'));
      expect(picked, isNull);
    });

    testWidgets('isDateEnabled disables individual days', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (d) => picked = d,
            initialMonth: _march,
            isDateEnabled: (d) => d.day != 15,
          ),
        ),
      );
      await tester.tap(find.text('15'));
      expect(picked, isNull);
      await tester.tap(find.text('16'));
      expect(picked, DateTime(2026, 3, 16));
    });
  });

  group('navigation', () {
    testWidgets('next and previous step the month', (tester) async {
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (_) {},
            initialMonth: _march,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();
      expect(find.text('April 2026'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Previous month'));
      await tester.pump();
      expect(find.text('March 2026'), findsOneWidget);
    });

    testWidgets('previous is disabled at the minimum month', (tester) async {
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (_) {},
            initialMonth: _march,
            minDate: DateTime(2026, 3),
          ),
        ),
      );
      expect(_enabled(tester, 'Previous month'), isFalse);
      expect(_enabled(tester, 'Next month'), isTrue);
    });

    testWidgets('controlled month reports changes and holds the value', (
      tester,
    ) async {
      DateTime? changed;
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (_) {},
            focusedMonth: _march,
            onMonthChanged: (m) => changed = m,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();
      // Controlled: the widget does not move on its own.
      expect(find.text('March 2026'), findsOneWidget);
      expect(changed, DateTime(2026, 4));
    });
  });

  group('keyboard', () {
    testWidgets('arrow keys move the focus and Enter selects', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (d) => picked = d,
            initialMonth: _march,
          ),
        ),
      );
      await tester.tap(find.text('15'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      // 15, +1 day = 16, +1 week = 23.
      expect(picked, DateTime(2026, 3, 23));
    });

    testWidgets('no focus ring from a pointer tap', (tester) async {
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (_) {},
            initialMonth: _march,
          ),
        ),
      );
      await tester.tap(find.text('15'));
      await tester.pump();
      expect(_hasRing(tester), isFalse);
    });
  });

  group('accessibility', () {
    testWidgets('mirrors under RTL without error', (tester) async {
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (_) {},
            initialMonth: _march,
          ),
          direction: TextDirection.rtl,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();
      expect(find.text('April 2026'), findsOneWidget);
    });

    testWidgets('a day cell activates through the semantics tap action', (
      tester,
    ) async {
      DateTime? picked;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (d) => picked = d,
            initialMonth: _march,
          ),
        ),
      );

      tester.semantics.performAction(
        find.semantics.byLabel('March 15, 2026'),
        SemanticsAction.tap,
      );
      await tester.pump();

      expect(picked, DateTime(2026, 3, 15));
      handle.dispose();
    });

    testWidgets('renders at text scale 2.0 without exception', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: host(
            FossCalendar.single(
              selected: DateTime(2026, 3, 15),
              onSelected: (_) {},
              initialMonth: _march,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('15'), findsOneWidget);
    });
  });

  group('keyboard extras', () {
    Future<void> pumpSingle(WidgetTester tester, void Function(DateTime) on) =>
        tester.pumpWidget(
          host(
            FossCalendar.single(
              selected: null,
              onSelected: on,
              initialMonth: _march,
            ),
          ),
        );

    testWidgets('Home and End move to the week ends', (tester) async {
      DateTime? picked;
      await pumpSingle(tester, (d) => picked = d);
      // March 15 2026 is a Sunday; a Monday-first week runs March 9 to 15.
      await tester.tap(find.text('15'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, DateTime(2026, 3, 9));

      await tester.tap(find.text('15'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, DateTime(2026, 3, 15));
    });

    testWidgets('Page keys move by month', (tester) async {
      DateTime? picked;
      await pumpSingle(tester, (d) => picked = d);
      await tester.tap(find.text('15'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(find.text('April 2026'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, DateTime(2026, 4, 15));
    });

    testWidgets('keyboard navigation raises the focus ring', (tester) async {
      await pumpSingle(tester, (_) {});
      await tester.tap(find.text('15'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(_hasRing(tester), isTrue);
    });

    testWidgets('keyboard focus lands on the visible selection', (
      tester,
    ) async {
      DateTime? picked;
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: DateTime(2026, 3, 15),
            onSelected: (d) => picked = d,
            initialMonth: _march,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, DateTime(2026, 3, 15));
    });
  });

  group('hover and style', () {
    testWidgets('a pointer hover repaints the day without error', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (_) {},
            initialMonth: _march,
          ),
        ),
      );
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('15')));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text('10')));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a full style override renders', (tester) async {
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: DateTime(2026, 3, 15),
            onSelected: (_) {},
            initialMonth: _march,
            style: const FossCalendarStyle(
              dayForegroundColor: Color(0xFF111111),
              mutedForegroundColor: Color(0xFF888888),
              selectedColor: Color(0xFF6D28D9),
              selectedForegroundColor: Color(0xFFFFFFFF),
              rangeColor: Color(0xFFEDE9FE),
              hoverColor: Color(0xFFF3F4F6),
              todayIndicatorColor: Color(0xFF6D28D9),
              selectedTodayIndicatorColor: Color(0xFFFFFFFF),
              focusRingColor: Color(0x806D28D9),
              chevronColor: Color(0xFF333333),
              dayRadius: 6,
              cellSize: 44,
              dayTextStyle: TextStyle(fontSize: 16),
              weekdayTextStyle: TextStyle(fontSize: 12),
              captionTextStyle: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
      expect(find.text('March 2026'), findsOneWidget);
    });
  });

  group('upper bound', () {
    testWidgets('next is disabled at the maximum month', (tester) async {
      DateTime? changed;
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (_) {},
            initialMonth: _march,
            maxDate: DateTime(2026, 3, 31),
            onMonthChanged: (m) => changed = m,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();
      expect(find.text('March 2026'), findsOneWidget);
      expect(changed, isNull);
    });
  });

  group('month seeding and clamping', () {
    testWidgets('opens on the current month with a today marker', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FossCalendar.single(selected: null, onSelected: (_) {})),
      );
      // Focusing the grid on the current month seeds focus onto today.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(find.byType(FossCalendar), findsOneWidget);
      // The current day exposes a "today" label, driving the marker paint.
      expect(find.bySemanticsLabel(RegExp('today')), findsWidgets);
    });

    testWidgets('seeds from the multiple selection', (tester) async {
      await tester.pumpWidget(
        host(
          FossCalendar.multiple(
            selected: {DateTime(2026, 3, 12)},
            onSelected: (_) {},
          ),
        ),
      );
      expect(find.text('March 2026'), findsOneWidget);
    });

    testWidgets('seeds from the range selection', (tester) async {
      await tester.pumpWidget(
        host(
          FossCalendar.range(
            selected: FossDateRange(
              start: DateTime(2026, 3, 10),
              end: DateTime(2026, 3, 20),
            ),
            onSelected: (_) {},
          ),
        ),
      );
      expect(find.text('March 2026'), findsOneWidget);
    });

    testWidgets('clamps an initial month below the minimum up', (tester) async {
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (_) {},
            initialMonth: DateTime(2026),
            minDate: DateTime(2026, 3),
          ),
        ),
      );
      expect(find.text('March 2026'), findsOneWidget);
    });

    testWidgets('clamps an initial month above the maximum down', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (_) {},
            initialMonth: DateTime(2026, 12),
            maxDate: DateTime(2026, 3, 31),
          ),
        ),
      );
      expect(find.text('March 2026'), findsOneWidget);
    });
  });

  group('keyboard clamps focus to the bounds', () {
    testWidgets('arrow up cannot cross below minDate', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (d) => picked = d,
            initialMonth: _march,
            minDate: DateTime(2026, 3, 10),
          ),
        ),
      );
      await tester.tap(find.text('10'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, DateTime(2026, 3, 10));
    });

    testWidgets('arrow down cannot cross above maxDate', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (d) => picked = d,
            initialMonth: _march,
            maxDate: DateTime(2026, 3, 20),
          ),
        ),
      );
      await tester.tap(find.text('20'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, DateTime(2026, 3, 20));
    });

    testWidgets('a focused nav button rings and activates by keyboard', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossCalendar.single(
            selected: null,
            onSelected: (_) {},
            initialMonth: _march,
          ),
        ),
      );
      // Tab past the grid onto the previous-month button, then activate it.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_hasRing(tester), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text('February 2026'), findsOneWidget);
    });
  });
}
