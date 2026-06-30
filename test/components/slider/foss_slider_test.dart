import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

import 'host.dart';

const double _width = 200;
const double _thumb = 20;

// Local x for a target [value] on a [_width]-wide LTR slider, given the
// edge-aligned thumb travel.
double _xFor(double value, {double min = 0, double max = 100}) {
  final fraction = (value - min) / (max - min);
  return _thumb / 2 + fraction * (_width - _thumb);
}

Offset _globalFor(WidgetTester tester, double localX) {
  final topLeft = tester.getTopLeft(find.byType(FossSlider));
  return topLeft + Offset(localX, 24);
}

class _Host extends StatefulWidget {
  const _Host({
    required this.onChanged,
    this.divisions,
    this.enabled = true,
    this.onChangeStart,
    this.onChangeEnd,
    this.textDirection = TextDirection.ltr,
    this.theme,
  });

  final ValueChanged<double> onChanged;
  final int? divisions;
  final bool enabled;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final TextDirection textDirection;
  final FossThemeData? theme;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  double _value = 50;

  @override
  Widget build(BuildContext context) {
    Widget slider = SizedBox(
      width: _width,
      child: FossSlider(
        value: _value,
        divisions: widget.divisions,
        enabled: widget.enabled,
        semanticLabel: 'Volume',
        onChangeStart: widget.onChangeStart,
        onChangeEnd: widget.onChangeEnd,
        onChanged: (v) {
          setState(() => _value = v);
          widget.onChanged(v);
        },
      ),
    );
    if (widget.theme case final theme?) {
      slider = FossTheme(data: theme, child: slider);
    }
    return host(
      Directionality(textDirection: widget.textDirection, child: slider),
    );
  }
}

ShapeDecoration _thumbDecoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(FossSlider),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as ShapeDecoration;

void main() {
  group('FossSlider value mapping', () {
    testWidgets('a track tap jumps the value to the pressed position', (
      tester,
    ) async {
      double? changed;
      await tester.pumpWidget(_Host(onChanged: (v) => changed = v));

      await tester.tapAt(_globalFor(tester, _xFor(75)));

      expect(changed, closeTo(75, 0.5));
    });

    testWidgets('clamps a press past the end to max', (tester) async {
      double? changed;
      await tester.pumpWidget(_Host(onChanged: (v) => changed = v));

      // The far inside edge sits past the thumb's travel and clamps to max.
      await tester.tapAt(_globalFor(tester, _width - 1));

      expect(changed, 100);
    });

    testWidgets('a drag reports rising values and brackets the gesture', (
      tester,
    ) async {
      final changes = <double>[];
      double? start;
      double? end;
      await tester.pumpWidget(
        _Host(
          onChanged: changes.add,
          onChangeStart: (v) => start = v,
          onChangeEnd: (v) => end = v,
        ),
      );

      await tester.timedDrag(
        find.byType(FossSlider),
        const Offset(40, 0),
        const Duration(milliseconds: 100),
      );

      expect(start, isNotNull);
      expect(changes.last, greaterThan(50));
      expect(end, changes.last);
    });

    testWidgets('divisions snap the value to the nearest step', (tester) async {
      double? changed;
      await tester.pumpWidget(
        _Host(divisions: 4, onChanged: (v) => changed = v),
      );

      // Raw 70 sits between the 50 and 75 steps and snaps up to 75.
      await tester.tapAt(_globalFor(tester, _xFor(70)));

      expect(changed, 75);
    });

    testWidgets('RTL maps the pressed position from the right', (tester) async {
      double? changed;
      await tester.pumpWidget(
        _Host(
          textDirection: TextDirection.rtl,
          onChanged: (v) => changed = v,
        ),
      );

      // The same x that reads 75 in LTR reads 25 from the right in RTL.
      await tester.tapAt(_globalFor(tester, _xFor(75)));

      expect(changed, closeTo(25, 0.5));
    });
  });

  group('FossSlider keyboard', () {
    Future<void> focus(WidgetTester tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }

    testWidgets('arrow keys step the value by a fraction of the range', (
      tester,
    ) async {
      double? changed;
      await tester.pumpWidget(_Host(onChanged: (v) => changed = v));
      await focus(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(changed, 55);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(changed, 50);
    });

    testWidgets('Home and End jump to the bounds', (tester) async {
      double? changed;
      await tester.pumpWidget(_Host(onChanged: (v) => changed = v));
      await focus(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(changed, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(changed, 100);
    });

    testWidgets('RTL flips the left and right arrows', (tester) async {
      double? changed;
      await tester.pumpWidget(
        _Host(textDirection: TextDirection.rtl, onChanged: (v) => changed = v),
      );
      await focus(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(changed, 45);
    });
  });

  group('FossSlider disabled', () {
    testWidgets('a null callback blocks taps and dims the control', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: _width,
            child: FossSlider(value: 50, onChanged: null),
          ),
        ),
      );

      await tester.tapAt(_globalFor(tester, _xFor(75)));

      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(FossSlider),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.64);
    });

    testWidgets('enabled false blocks input', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _Host(enabled: false, onChanged: (_) => taps++),
      );

      await tester.tapAt(_globalFor(tester, _xFor(75)));

      expect(taps, 0);
    });
  });

  group('FossSlider thumb', () {
    testWidgets('rests on a white knob with the input border', (tester) async {
      await tester.pumpWidget(_Host(onChanged: (_) {}));

      final decoration = _thumbDecoration(tester);
      expect(decoration.color, const Color(0xFFFFFFFF));
      expect(
        (decoration.shape as CircleBorder).side.color,
        FossThemeData.light.colors.input,
      );
    });

    testWidgets('dark switches the thumb border to the surface', (
      tester,
    ) async {
      await tester.pumpWidget(
        _Host(theme: FossThemeData.dark, onChanged: (_) {}),
      );

      expect(
        (_thumbDecoration(tester).shape as CircleBorder).side.color,
        FossThemeData.dark.colors.background,
      );
    });
  });

  group('FossSlider accessibility', () {
    testWidgets('exposes the slider role, value, and step actions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_Host(onChanged: (_) {}));

      final data = tester
          .getSemantics(find.byType(FossSlider))
          .getSemanticsData();
      expect(data.flagsCollection.isSlider, isTrue);
      expect(data.label, 'Volume');
      expect(data.value, '50');
      expect(data.hasAction(SemanticsAction.increase), isTrue);
      expect(data.hasAction(SemanticsAction.decrease), isTrue);
      handle.dispose();
    });

    testWidgets('meets the minimum tap target', (tester) async {
      await tester.pumpWidget(_Host(onChanged: (_) {}));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('holds its height under 2x text scale', (tester) async {
      await tester.pumpWidget(_Host(onChanged: (_) {}));
      final base = tester.getSize(find.byType(FossSlider));

      await tester.pumpWidget(
        host(
          MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: const SizedBox(
              width: _width,
              child: FossSlider(value: 50, onChanged: _noop),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(FossSlider)), base);
      expect(tester.takeException(), isNull);
    });
  });
}

void _noop(double _) {}
