import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

// An interactive mark pads out to the 48px tap-target floor, so a five-mark
// row is 240 wide and every mark owns a 48-wide slice.
const double _hit = 48;

void _noop(double _) {}

// One mark is the only directional Stack in the tree, so this counts marks
// without reaching for a private type.
final Finder _marks = find.byWidgetPredicate(
  (w) => w is Stack && w.alignment == AlignmentDirectional.centerStart,
);

// The fill fraction of every partially or fully filled mark, in paint order.
// An empty mark builds no clipped layer, so it contributes nothing. The clip is
// what distinguishes a fill layer from the box the control hugs itself with.
List<double> _fills(WidgetTester tester) => tester
    .widgetList<Align>(
      find.descendant(
        of: find.byType(ClipRect),
        matching: find.byWidgetPredicate(
          (w) => w is Align && w.widthFactor != null,
        ),
      ),
    )
    .map((a) => a.widthFactor ?? 0)
    .toList();

// The center of the mark at [index], offset by [withinMark] across its slice
// (0 is the leading edge, 1 the trailing one).
Offset _at(WidgetTester tester, int index, {double withinMark = 0.5}) {
  final box = tester.getRect(find.byType(FossRating));
  return Offset(
    box.left + (index + withinMark) * _hit,
    box.center.dy,
  );
}

// The control's own semantics node. It sits inside the box the widget hugs
// itself with, so it is a descendant rather than the widget root.
final Finder _node = find
    .descendant(of: find.byType(FossRating), matching: find.byType(Semantics))
    .first;

class _Host extends StatefulWidget {
  const _Host({
    this.onChanged,
    this.initial = 3,
    this.precision = FossRatingPrecision.full,
    this.enabled = true,
    this.textDirection = TextDirection.ltr,
  });

  final ValueChanged<double>? onChanged;
  final double initial;
  final FossRatingPrecision precision;
  final bool enabled;
  final TextDirection textDirection;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late double _value = widget.initial;

  @override
  Widget build(BuildContext context) => host(
    Directionality(
      textDirection: widget.textDirection,
      child: FossRating(
        value: _value,
        precision: widget.precision,
        enabled: widget.enabled,
        semanticLabel: 'Rating',
        onChanged: (v) {
          setState(() => _value = v);
          widget.onChanged?.call(v);
        },
      ),
    ),
  );
}

void main() {
  group('FossRating structure', () {
    testWidgets('draws one mark per count', (tester) async {
      await tester.pumpWidget(host(const FossRating(value: 2, count: 7)));

      expect(_marks, findsNWidgets(7));
    });

    testWidgets('fills whole marks up to the value', (tester) async {
      await tester.pumpWidget(host(const FossRating(value: 3)));

      expect(_fills(tester), [1, 1, 1]);
    });

    testWidgets('clips the last mark to the exact fraction', (tester) async {
      await tester.pumpWidget(const _Host(initial: 3.5, onChanged: _noop));

      expect(_fills(tester), [1, 1, 1, 0.5]);
    });

    testWidgets('paints an average at its true fraction, not a half', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FossRating(value: 4.3)));

      expect(_fills(tester), [1, 1, 1, 1, closeTo(0.3, 0.0001)]);
    });

    testWidgets('a zero value fills nothing', (tester) async {
      await tester.pumpWidget(host(const FossRating(value: 0)));

      expect(_marks, findsNWidgets(5));
      expect(_fills(tester), isEmpty);
    });

    testWidgets('clamps a value past the ends rather than throwing', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FossRating(value: 7.2)));
      expect(_fills(tester), [1, 1, 1, 1, 1]);

      await tester.pumpWidget(host(const FossRating(value: -3)));
      expect(_fills(tester), isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('each size paints its own glyph box', (tester) async {
      for (final (size, box) in [
        (FossRatingSize.sm, 16.0),
        (FossRatingSize.md, 20.0),
        (FossRatingSize.lg, 24.0),
      ]) {
        await tester.pumpWidget(host(FossRating(value: 1, size: size)));

        expect(tester.getSize(_marks.first), Size.square(box));
      }
    });

    testWidgets('an interactive row pads every mark to the tap floor', (
      tester,
    ) async {
      await tester.pumpWidget(const _Host(onChanged: _noop));

      expect(tester.getSize(find.byType(FossRating)).width, _hit * 5);
    });

    testWidgets('a display row hugs its glyphs and gaps', (tester) async {
      await tester.pumpWidget(host(const FossRating(value: 3)));

      // Five md marks at 20 with four 4px gaps between them.
      expect(tester.getSize(find.byType(FossRating)).width, 20 * 5 + 4 * 4);
    });
  });

  group('FossRating input', () {
    testWidgets('a tap sets the value to the pressed mark', (tester) async {
      double? changed;
      await tester.pumpWidget(_Host(onChanged: (v) => changed = v));

      await tester.tapAt(_at(tester, 3));

      expect(changed, 4);
    });

    testWidgets('full precision ignores where in the mark the tap lands', (
      tester,
    ) async {
      final changes = <double>[];
      await tester.pumpWidget(_Host(onChanged: changes.add, initial: 5));

      await tester.tapAt(_at(tester, 1, withinMark: 0.1));
      await tester.pump();
      await tester.tapAt(_at(tester, 1, withinMark: 0.9));

      expect(changes, [2]);
    });

    testWidgets('half precision splits each mark down the middle', (
      tester,
    ) async {
      final changes = <double>[];
      await tester.pumpWidget(
        _Host(
          precision: FossRatingPrecision.half,
          onChanged: changes.add,
          initial: 5,
        ),
      );

      await tester.tapAt(_at(tester, 2, withinMark: 0.25));
      await tester.pump();
      await tester.tapAt(_at(tester, 2, withinMark: 0.75));

      expect(changes, [2.5, 3]);
    });

    testWidgets('a drag reports each mark it crosses', (tester) async {
      final changes = <double>[];
      await tester.pumpWidget(_Host(onChanged: changes.add, initial: 1));

      final gesture = await tester.startGesture(_at(tester, 0));
      await gesture.moveTo(_at(tester, 2));
      await tester.pump();
      await gesture.moveTo(_at(tester, 4));
      await tester.pump();
      await gesture.up();

      expect(changes, [3, 5]);
    });

    testWidgets('a tap on the first mark never clears the value', (
      tester,
    ) async {
      final changes = <double>[];
      await tester.pumpWidget(_Host(onChanged: changes.add, initial: 1));

      await tester.tapAt(_at(tester, 0, withinMark: 0.05));

      expect(changes, isEmpty);
      expect(_fills(tester), [1]);
    });

    testWidgets('a tight parent does not stretch the marks out of reach', (
      tester,
    ) async {
      double? changed;
      // A list hands its children a tight cross-axis width. If the row took it,
      // the marks would stay at the start while the pointer maths spread its
      // slices across the full width, and every tap would land on the wrong
      // mark.
      await tester.pumpWidget(
        host(
          ListView(
            children: [
              FossRating(value: 1, onChanged: (v) => changed = v),
            ],
          ),
        ),
      );

      // The outer box takes the width it is handed; the control inside keeps
      // its own, which is what the pointer maths measures against.
      expect(tester.getSize(find.byType(FossRating)).width, 800);
      expect(tester.getSize(_node).width, _hit * 5);

      await tester.tapAt(_at(tester, 4));

      expect(changed, 5);
    });

    testWidgets('RTL reads the pressed position from the end', (tester) async {
      double? changed;
      await tester.pumpWidget(
        _Host(
          textDirection: TextDirection.rtl,
          onChanged: (v) => changed = v,
        ),
      );

      // The slice that reads 4 in LTR is the second from the end in RTL.
      await tester.tapAt(_at(tester, 3));

      expect(changed, 2);
    });
  });

  group('FossRating keyboard', () {
    Future<void> focus(WidgetTester tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }

    testWidgets('arrow keys step by the precision step', (tester) async {
      final changes = <double>[];
      await tester.pumpWidget(_Host(onChanged: changes.add));
      await focus(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(changes, [4, 3]);
    });

    testWidgets('half precision steps by a half', (tester) async {
      final changes = <double>[];
      await tester.pumpWidget(
        _Host(precision: FossRatingPrecision.half, onChanged: changes.add),
      );
      await focus(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(changes, [3.5]);
    });

    testWidgets('Home and End reach both ends', (tester) async {
      final changes = <double>[];
      await tester.pumpWidget(_Host(onChanged: changes.add));
      await focus(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();

      expect(changes, [5, 1]);
    });

    testWidgets('RTL flips the left and right arrows', (tester) async {
      final changes = <double>[];
      await tester.pumpWidget(
        _Host(textDirection: TextDirection.rtl, onChanged: changes.add),
      );
      await focus(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(changes, [2]);
    });

    testWidgets('keyboard focus paints the ring', (tester) async {
      await tester.pumpWidget(const _Host(onChanged: _noop));
      final before = tester
          .widgetList(
            find.descendant(
              of: find.byType(FossRating),
              matching: find.byType(CustomPaint),
            ),
          )
          .length;

      await focus(tester);

      expect(
        tester
            .widgetList(
              find.descendant(
                of: find.byType(FossRating),
                matching: find.byType(CustomPaint),
              ),
            )
            .length,
        greaterThan(before),
      );
    });
  });

  group('FossRating display and disabled', () {
    testWidgets('a null callback blocks taps and takes no focus', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FossRating(value: 3)));

      await tester.tapAt(_at(tester, 4));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(_fills(tester), [1, 1, 1]);
      expect(
        find.descendant(
          of: find.byType(FossRating),
          matching: find.byType(FocusableActionDetector),
        ),
        findsNothing,
      );
    });

    testWidgets('enabled false blocks input and dims the row', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _Host(enabled: false, onChanged: (_) => taps++),
      );

      await tester.tapAt(_at(tester, 4));

      expect(taps, 0);
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(FossRating),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        0.64,
      );
    });
  });

  group('FossRating theming', () {
    testWidgets('a style override drives the glyph box and gap', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FossRating(
            value: 3,
            style: FossRatingStyle(glyphSize: 28, gap: 10),
          ),
        ),
      );

      expect(tester.getSize(_marks.first), const Size.square(28));
      expect(tester.getSize(find.byType(FossRating)).width, 28 * 5 + 10 * 4);
    });

    testWidgets('custom icon slots replace both marks and keep the clip', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FossRating(
            value: 2.5,
            emptyIcon: Text('o'),
            filledIcon: Text('x'),
          ),
        ),
      );

      // A full mark drops its empty layer, so only the three unfilled and the
      // one half-filled mark draw the empty icon.
      expect(find.text('o'), findsNWidgets(3));
      expect(find.text('x'), findsNWidgets(3));
      expect(_fills(tester), [1, 1, 0.5]);
    });

    testWidgets('dark resolves from the roles', (tester) async {
      await tester.pumpWidget(
        host(
          FossTheme(
            data: FossThemeData.dark,
            child: const FossRating(value: 3),
          ),
        ),
      );

      expect(_marks, findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });
  });

  group('FossRating accessibility', () {
    testWidgets('exposes the value, label, and step actions', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(const _Host(onChanged: _noop));

      final data = tester.getSemantics(_node).getSemanticsData();
      expect(data.flagsCollection.isSlider, isTrue);
      expect(data.label, 'Rating');
      expect(data.value, '3 of 5');
      expect(data.hasAction(SemanticsAction.increase), isTrue);
      expect(data.hasAction(SemanticsAction.decrease), isTrue);
      handle.dispose();
    });

    testWidgets('announces a fractional value to one decimal', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const FossRating(value: 4.3)));

      expect(
        tester.getSemantics(_node).getSemanticsData().value,
        '4.3 of 5',
      );
      handle.dispose();
    });

    testWidgets('drops the step action at each bound', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const FossRating(value: 5, onChanged: _noop)),
      );
      expect(
        tester
            .getSemantics(_node)
            .getSemanticsData()
            .hasAction(SemanticsAction.increase),
        isFalse,
      );

      await tester.pumpWidget(
        host(const FossRating(value: 1, onChanged: _noop)),
      );
      expect(
        tester
            .getSemantics(_node)
            .getSemanticsData()
            .hasAction(SemanticsAction.decrease),
        isFalse,
      );
      handle.dispose();
    });

    testWidgets('semantic increase and decrease step the value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final changes = <double>[];
      await tester.pumpWidget(_Host(onChanged: changes.add));

      tester.semantics.increase(find.semantics.byLabel('Rating'));
      await tester.pump();
      tester.semantics.decrease(find.semantics.byLabel('Rating'));
      await tester.pump();

      expect(changes, [4, 3]);
      handle.dispose();
    });

    testWidgets('a display row announces its value without actions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const FossRating(value: 2, semanticLabel: 'Average')),
      );

      final data = tester.getSemantics(_node).getSemanticsData();
      expect(data.label, 'Average');
      expect(data.value, '2 of 5');
      expect(data.hasAction(SemanticsAction.increase), isFalse);
      handle.dispose();
    });

    testWidgets('a disabled row announces as disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const _Host(enabled: false, onChanged: _noop),
      );

      final data = tester.getSemantics(_node).getSemanticsData();
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      handle.dispose();
    });

    testWidgets('meets the minimum tap target', (tester) async {
      await tester.pumpWidget(const _Host(onChanged: _noop));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    });

    testWidgets('holds its size under 2x text scale', (tester) async {
      await tester.pumpWidget(host(const FossRating(value: 3)));
      final base = tester.getSize(find.byType(FossRating));

      await tester.pumpWidget(
        host(
          MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: const FossRating(value: 3),
          ),
        ),
      );

      expect(tester.getSize(find.byType(FossRating)), base);
      expect(tester.takeException(), isNull);
    });
  });

  group('FossRating constructor', () {
    test('rejects a non-positive count', () {
      expect(
        () => FossRating(value: 1, count: 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
