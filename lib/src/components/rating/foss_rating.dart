import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/src/foundation/foss_since.dart';
import 'package:fossui/src/icons/foss_glyph.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_rating_style.dart';

// Fixed control geometry. An interactive mark pads out to the platform
// tap-target floor, so an interactive row is wider than its glyphs while the
// painted marks keep their size.
const double _hitExtent = 48;
const double _ringWidth = 2;
const double _ringOffset = 1;
const double _disabledOpacity = 0.64;

/// Glyph box of a [FossRating], in logical pixels.
///
/// The box is an icon extent rather than a text size, so it does not grow with
/// the text scale and the row keeps its height.
///
/// ```dart
/// FossRating(value: 4, size: FossRatingSize.lg);
/// ```
@FossSince('0.1.3')
enum FossRatingSize {
  /// Compact: 16 logical pixels, matching the inline icon step.
  sm,

  /// Default: 20 logical pixels.
  md,

  /// Prominent: 24 logical pixels.
  lg,
}

/// Granularity a [FossRating] snaps input to.
///
/// Display is unaffected: a rating always paints the exact fraction it is
/// given, so an average of 4.3 reads as 4.3 under either value.
///
/// ```dart
/// FossRating(
///   value: 3.5,
///   precision: FossRatingPrecision.half,
///   onChanged: (v) {},
/// );
/// ```
@FossSince('0.1.3')
enum FossRatingPrecision {
  /// Input snaps to whole marks.
  full,

  /// Input snaps to halves.
  half,
}

/// {@category Inputs}
/// {@template foss.rating.preview}
/// <img src="https://fossui.org/components/rating/overview/light.png"
///   alt="FossRating, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/rating/overview/dark.png"
///   alt="FossRating, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [rating documentation ↗](https://fossui.org/docs/components/rating)
/// or try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/rating/fossrating/playground).
/// {@endtemplate}
///
/// A row of [count] star marks standing for [value], a [double] in `0..count`.
///
/// One widget covers both jobs. Pass [onChanged] and the row takes a rating: a
/// tap or a horizontal drag sets the value, arrow keys step it, and Home and
/// End reach both ends. Leave [onChanged] null and the row is a read-only
/// display that still announces its value, which is what an average needs.
/// That is separate from `enabled: false`, an interactive row currently
/// refusing input.
///
/// [precision] snaps input to whole marks or to halves, and never affects
/// display: the last filled mark is clipped to the exact fraction, so 4.3
/// paints as 4.3. Supply [emptyIcon] and [filledIcon] to swap the marks for any
/// icon set; both are clipped the same way, so a custom pair keeps the partial
/// fill. Input never reaches 0, so a tap always registers as a rating. Colors
/// and spacing come from `context.fossTheme`; pass a [FossRatingStyle] to
/// [style] for a one-off.
///
/// {@macro foss.customize}
///
/// See also `FossSlider` for picking a continuous value from a range.
///
/// ```dart
/// FossRating(
///   value: _score,
///   precision: FossRatingPrecision.half,
///   onChanged: (v) => setState(() => _score = v),
///   semanticLabel: 'Overall rating',
/// );
/// ```
@FossSince('0.1.3')
class FossRating extends StatefulWidget {
  /// {@macro foss.rating.preview}
  ///
  /// Creates a rating at [value], out of [count] marks.
  const FossRating({
    required this.value,
    this.count = 5,
    this.onChanged,
    this.precision = FossRatingPrecision.full,
    this.size = FossRatingSize.md,
    this.enabled = true,
    this.emptyIcon,
    this.filledIcon,
    this.semanticLabel,
    this.style,
    super.key,
  }) : assert(count > 0, 'count must be positive');

  /// The current rating. Clamped into `0..count` when painted, so an
  /// out-of-range value reads as the nearest bound rather than throwing.
  final double value;

  /// How many marks the row draws. Defaults to 5.
  final int count;

  /// Called with the new rating on a tap, drag, or key press. A null callback
  /// makes the row a read-only display.
  final ValueChanged<double>? onChanged;

  /// Granularity input snaps to. Has no effect on display.
  final FossRatingPrecision precision;

  /// Glyph box of each mark.
  final FossRatingSize size;

  /// Whether an interactive row accepts input. A false value dims the row and
  /// announces it as disabled. It differs from a null [onChanged], which is a
  /// display rather than a blocked control.
  final bool enabled;

  /// The unfilled mark, sized to the [size] box. Defaults to an outline star.
  final Widget? emptyIcon;

  /// The filled mark, sized to the [size] box and clipped for a partial mark.
  /// Defaults to a solid star.
  final Widget? filledIcon;

  /// Accessibility name for the control.
  final String? semanticLabel;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossRatingStyle? style;

  @override
  State<FossRating> createState() => _FossRatingState();
}

class _FossRatingState extends State<FossRating> {
  final WidgetStatesController _states = WidgetStatesController();
  final GlobalKey _rowKey = GlobalKey();

  bool get _interactive => widget.onChanged != null;

  bool get _enabled => widget.enabled && _interactive;

  double get _count => widget.count.toDouble();

  double get _value => widget.value.clamp(0, _count);

  double get _step => switch (widget.precision) {
    FossRatingPrecision.full => 1.0,
    FossRatingPrecision.half => 0.5,
  };

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  // Rounds up onto the precision step, so the lower half of a mark reads as the
  // half and the upper half as the whole, then clamps into `step..count`.
  // Input never reaches 0: a tap on the first mark is a rating of one, not a
  // reset, so a stray tap cannot silently wipe a value.
  double _snap(double value) =>
      ((value / _step).ceil() * _step).clamp(_step, _count);

  // Maps a global pointer position to a snapped rating through the row's box,
  // so the maths respects the laid-out width and the reading direction. In an
  // interactive row every mark owns an equal slice of that width, hit box
  // included.
  double? _pointerToValue(Offset global) {
    final box = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final width = box.size.width;
    if (width <= 0) return null;
    final dx = box.globalToLocal(global).dx;
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final fromStart = (ltr ? dx : width - dx).clamp(0.0, width);
    return _snap(fromStart / (width / widget.count));
  }

  void _emit(double value) {
    if (value != widget.value) widget.onChanged?.call(value);
  }

  void _emitPointer(Offset global) {
    if (_pointerToValue(global) case final value?) _emit(value);
  }

  void _emitStep(double value) => _emit(_snap(value));

  Map<ShortcutActivator, Intent> _shortcuts(TextDirection direction) {
    final ltr = direction == TextDirection.ltr;
    const inc = _RatingIncrementIntent();
    const dec = _RatingDecrementIntent();
    return {
      const SingleActivator(LogicalKeyboardKey.arrowUp): inc,
      const SingleActivator(LogicalKeyboardKey.arrowDown): dec,
      const SingleActivator(LogicalKeyboardKey.arrowRight): ltr ? inc : dec,
      const SingleActivator(LogicalKeyboardKey.arrowLeft): ltr ? dec : inc,
      const SingleActivator(LogicalKeyboardKey.home): const _RatingMinIntent(),
      const SingleActivator(LogicalKeyboardKey.end): const _RatingMaxIntent(),
    };
  }

  Map<Type, Action<Intent>> get _actions => {
    _RatingIncrementIntent: CallbackAction<_RatingIncrementIntent>(
      onInvoke: (_) {
        _emitStep(_value + _step);
        return null;
      },
    ),
    _RatingDecrementIntent: CallbackAction<_RatingDecrementIntent>(
      onInvoke: (_) {
        _emitStep(_value - _step);
        return null;
      },
    ),
    _RatingMinIntent: CallbackAction<_RatingMinIntent>(
      onInvoke: (_) {
        _emitStep(_step);
        return null;
      },
    ),
    _RatingMaxIntent: CallbackAction<_RatingMaxIntent>(
      onInvoke: (_) {
        _emitStep(_count);
        return null;
      },
    ),
  };

  @override
  Widget build(BuildContext context) {
    final v = _apply(_resolve(context.fossTheme, widget.size), widget.style);
    final direction = Directionality.of(context);

    final row = Row(
      key: _rowKey,
      mainAxisSize: MainAxisSize.min,
      // Interactive hit boxes abut, so the gap lives inside them and the
      // pointer maths can treat the row as equal slices.
      spacing: _interactive ? 0 : v.gap,
      children: [
        for (var i = 0; i < widget.count; i++)
          _mark(v, fill: (_value - i).clamp(0.0, 1.0)),
      ],
    );

    if (!_interactive) {
      return _hug(
        Semantics(
          label: widget.semanticLabel,
          value: _format(_value),
          child: row,
        ),
      );
    }

    Widget control = ListenableBuilder(
      listenable: _states,
      builder: (_, _) => _states.value.contains(WidgetState.focused)
          ? CustomPaint(
              foregroundPainter: _FocusRingPainter(
                color: v.ringColor,
                offsetColor: v.ringOffsetColor,
                radius: v.ringRadius,
              ),
              child: row,
            )
          : row,
    );

    control = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _enabled ? (d) => _emitPointer(d.globalPosition) : null,
      onHorizontalDragStart: _enabled
          ? (d) => _emitPointer(d.globalPosition)
          : null,
      onHorizontalDragUpdate: _enabled
          ? (d) => _emitPointer(d.globalPosition)
          : null,
      child: control,
    );

    control = FocusableActionDetector(
      enabled: _enabled,
      mouseCursor: _enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      shortcuts: _enabled ? _shortcuts(direction) : null,
      actions: _enabled ? _actions : null,
      onShowFocusHighlight: (value) =>
          _states.update(WidgetState.focused, value),
      child: control,
    );

    if (!_enabled) {
      control = Opacity(opacity: _disabledOpacity, child: control);
    }

    return _hug(
      Semantics(
        slider: true,
        enabled: _enabled,
        label: widget.semanticLabel,
        value: _format(_value),
        increasedValue: _format(_snap(_value + _step)),
        decreasedValue: _format(_snap(_value - _step)),
        // Drop the action at the bound it cannot move past, so a screen reader
        // never announces an unchanged value at either end.
        onIncrease: _enabled && _value < _count
            ? () => _emitStep(_value + _step)
            : null,
        onDecrease: _enabled && _value > _step
            ? () => _emitStep(_value - _step)
            : null,
        child: control,
      ),
    );
  }

  // Keeps the control at its content width even where the parent hands down a
  // tight one, as a list or a column does. Without this the row stretches, the
  // marks stay at the start, and the pointer maths reads slices that no longer
  // line up with them. The child is laid out loose, so it still hugs; the box
  // around it only fills what the parent insists on.
  Widget _hug(Widget child) => Align(
    alignment: AlignmentDirectional.centerStart,
    widthFactor: 1,
    heightFactor: 1,
    child: child,
  );

  // One mark: the empty layer with the filled layer clipped over it. The clip
  // and the stack both align directionally, so a partial mark fills from the
  // end under RTL without a second code path.
  Widget _mark(_RatingVisuals v, {required double fill}) {
    final glyph = Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [
        // A full mark skips the empty layer: the outline strokes astride its
        // own path, so half of it would fringe the solid fill laid over it.
        if (fill < 1)
          _layer(v.glyphSize, widget.emptyIcon, StarGlyph(v.emptyColor)),
        if (fill > 0)
          ClipRect(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: fill,
              // A null factor makes that axis take the incoming maximum, so the
              // height has to shrink-wrap explicitly or the mark grows tall.
              heightFactor: 1,
              child: _layer(
                v.glyphSize,
                widget.filledIcon,
                StarGlyph(v.filledColor, filled: true),
              ),
            ),
          ),
      ],
    );

    return _interactive
        ? SizedBox(
            width: _hitExtent,
            height: _hitExtent,
            child: Center(child: glyph),
          )
        : glyph;
  }

  // One layer of a mark at the glyph box: the caller's icon when supplied,
  // otherwise the built-in star. A supplied icon is excluded from the semantics
  // tree so it does not announce once per mark.
  Widget _layer(double box, Widget? icon, FossGlyph fallback) =>
      SizedBox.square(
        dimension: box,
        child: icon == null
            ? FossGlyphIcon(fallback)
            : ExcludeSemantics(child: icon),
      );

  String _format(double value) => value == value.roundToDouble()
      ? '${value.toStringAsFixed(0)} of ${widget.count}'
      : '${value.toStringAsFixed(1)} of ${widget.count}';
}

class _RatingIncrementIntent extends Intent {
  const _RatingIncrementIntent();
}

class _RatingDecrementIntent extends Intent {
  const _RatingDecrementIntent();
}

class _RatingMinIntent extends Intent {
  const _RatingMinIntent();
}

class _RatingMaxIntent extends Intent {
  const _RatingMaxIntent();
}

/// Builds the default appearance for [size] from the theme tokens.
_RatingVisuals _resolve(FossThemeData theme, FossRatingSize size) {
  final c = theme.colors;
  final (glyphSize, gap) = switch (size) {
    FossRatingSize.sm => (16.0, theme.spacing(0.5)),
    FossRatingSize.md => (20.0, theme.spacing(1)),
    FossRatingSize.lg => (24.0, theme.spacing(1)),
  };
  return _RatingVisuals(
    filledColor: c.primary,
    emptyColor: c.mutedForeground,
    ringColor: c.ring,
    ringOffsetColor: c.background,
    ringRadius: theme.radii.sm,
    glyphSize: glyphSize,
    gap: gap,
  );
}

/// Lays a per-instance [override] over the resolved [base], field by field.
_RatingVisuals _apply(_RatingVisuals base, FossRatingStyle? override) {
  if (override == null) return base;
  return _RatingVisuals(
    filledColor: override.filledColor ?? base.filledColor,
    emptyColor: override.emptyColor ?? base.emptyColor,
    ringColor: base.ringColor,
    ringOffsetColor: base.ringOffsetColor,
    ringRadius: base.ringRadius,
    glyphSize: override.glyphSize ?? base.glyphSize,
    gap: override.gap ?? base.gap,
  );
}

/// The fully resolved, non-null appearance for one size. A [FossRatingStyle]
/// override is laid over it by [_apply], so the widget reads only non-null
/// fields. The ring stays token-driven and is not overridable per instance.
@immutable
class _RatingVisuals {
  const _RatingVisuals({
    required this.filledColor,
    required this.emptyColor,
    required this.ringColor,
    required this.ringOffsetColor,
    required this.ringRadius,
    required this.glyphSize,
    required this.gap,
  });

  final Color filledColor;
  final Color emptyColor;
  final Color ringColor;
  final Color ringOffsetColor;
  final double ringRadius;
  final double glyphSize;
  final double gap;
}

/// Paints the focus ring around the whole row: the house 2px ring in the `ring`
/// role over a 1px offset in `background`, on superellipse corners.
class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter({
    required this.color,
    required this.offsetColor,
    required this.radius,
  });

  final Color color;
  final Color offsetColor;
  final double radius;

  RSuperellipse _shape(Rect box, double grow) =>
      RSuperellipse.fromRectAndRadius(
        box.inflate(grow),
        Radius.circular(radius + grow),
      );

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    canvas
      ..drawRSuperellipse(
        _shape(box, _ringOffset / 2),
        Paint()
          ..color = offsetColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringOffset,
      )
      ..drawRSuperellipse(
        _shape(box, _ringOffset + _ringWidth / 2),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringWidth,
      );
  }

  @override
  bool shouldRepaint(_FocusRingPainter old) =>
      old.color != color ||
      old.offsetColor != offsetColor ||
      old.radius != radius;
}
