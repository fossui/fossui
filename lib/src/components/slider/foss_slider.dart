import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_slider_style.dart';

// Fixed control geometry: the track bar, the thumb, and the touch target.
// Mobile base values; none is token-able (nothing else references them).
const double _trackHeight = 4;
const double _thumbSize = 20;
const double _trackInset = 2;
const double _rangeMargin = 2;
const double _ringWidth = 3;
const double _dragScale = 1.2;
const double _disabledOpacity = 0.64;
const double _controlHeight = 48;
const double _minTrackWidth = 176;

// Focus ring alpha on the `ring` role: lighter in light mode, lifted in dark.
const double _ringAlphaLight = 0.24;
const double _ringAlphaDark = 0.48;

// Keyboard step when continuous: a twentieth of the range per arrow press.
const double _continuousStep = 0.05;

// The thumb scale is the one animated transition; gated under reduced motion.
const Duration _dragScaleDuration = Duration(milliseconds: 150);

// A white knob in both themes (the one baked control color), with a faint 1px
// dark rim along its top inner edge at rest.
const Color _knobColor = Color(0xFFFFFFFF);
const Color _thumbRim = Color(0x0A000000);

/// {@category Inputs}
/// {@template foss.slider.preview}
/// <img src="https://fossui.org/components/slider/overview/light.png"
///   alt="FossSlider, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/slider/overview/dark.png"
///   alt="FossSlider, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [slider documentation ↗](https://fossui.org/docs/components/slider) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/slider/fossslider/playground).
/// {@endtemplate}
///
/// A horizontal slider: a track with a draggable thumb that picks a [double]
/// from `[min, max]`.
///
/// Continuous by default; pass [divisions] to snap to equal steps. A drag or a
/// track tap maps the pointer to a value and reports it through [onChanged];
/// [onChangeStart] and [onChangeEnd] bracket a drag. Passing `null` to
/// [onChanged] or `false` to [enabled] disables the control. Arrow keys step
/// the value, Home and End jump to [min] and [max]. Colors come from
/// `context.fossTheme`; pass a [FossSliderStyle] to [style] for a one-off.
///
/// {@macro foss.customize}
///
/// ```dart
/// FossSlider(
///   value: _volume,
///   onChanged: (v) => setState(() => _volume = v),
///   semanticLabel: 'Volume',
/// );
/// ```
class FossSlider extends StatefulWidget {
  /// {@macro foss.slider.preview}
  ///
  /// Creates a slider at [value], within `[min, max]`.
  const FossSlider({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.onChangeStart,
    this.onChangeEnd,
    this.enabled = true,
    this.semanticLabel,
    this.style,
    super.key,
  }) : assert(min <= max, 'min must be <= max'),
       assert(
         divisions == null || divisions > 0,
         'divisions must be positive',
       );

  /// The current value, within `[min, max]`. The caller holds and clamps it.
  final double value;

  /// Called with the new value as the thumb moves; `null` disables the control.
  final ValueChanged<double>? onChanged;

  /// Lower bound of the range. Defaults to 0.
  final double min;

  /// Upper bound of the range. Defaults to 100.
  final double max;

  /// Number of equal steps to snap to; `null` is continuous.
  final int? divisions;

  /// Called with the starting value when a drag begins.
  final ValueChanged<double>? onChangeStart;

  /// Called with the final value when a drag ends.
  final ValueChanged<double>? onChangeEnd;

  /// Whether the control accepts input. Disabled when false or [onChanged] is
  /// `null`.
  final bool enabled;

  /// Accessibility name for the control.
  final String? semanticLabel;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossSliderStyle? style;

  @override
  State<FossSlider> createState() => _FossSliderState();
}

class _FossSliderState extends State<FossSlider> {
  final WidgetStatesController _states = WidgetStatesController();
  final GlobalKey _trackKey = GlobalKey();

  // True between a press and its release, so a press that becomes a drag does
  // not open a second value-change session.
  bool _inSession = false;

  bool get _enabled => widget.enabled && widget.onChanged != null;

  @override
  void initState() {
    super.initState();
    _states.update(WidgetState.disabled, !_enabled);
  }

  @override
  void didUpdateWidget(FossSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    _states.update(WidgetState.disabled, !_enabled);
  }

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  double get _range => widget.max - widget.min;

  double get _fraction =>
      _range == 0 ? 0 : ((widget.value - widget.min) / _range).clamp(0.0, 1.0);

  // Clamps to the range, then snaps to the nearest division when stepped.
  double _snap(double value) {
    final clamped = value.clamp(widget.min, widget.max);
    final divisions = widget.divisions;
    if (divisions == null) return clamped;
    final step = _range / divisions;
    return widget.min + (((clamped - widget.min) / step).round() * step);
  }

  double get _keyboardStep {
    final divisions = widget.divisions;
    if (divisions != null) return _range / divisions;
    return _range * _continuousStep;
  }

  // Maps a global pointer position to a snapped value via the track's box, so
  // the math respects the laid-out width and the reading direction.
  double? _pointerToValue(Offset global) {
    final box = _trackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final width = box.size.width;
    final travel = width - _thumbSize;
    if (travel <= 0) return widget.value;
    final dx = box.globalToLocal(global).dx;
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final fromStart = (ltr ? dx : width - dx) - _thumbSize / 2;
    final fraction = (fromStart / travel).clamp(0.0, 1.0);
    return _snap(widget.min + fraction * _range);
  }

  void _startSession(Offset global) {
    if (_pointerToValue(global) case final value?) {
      _inSession = true;
      _states.update(WidgetState.dragged, true);
      widget.onChangeStart?.call(value);
      widget.onChanged?.call(value);
    }
  }

  void _updateSession(Offset global) {
    if (_pointerToValue(global) case final value?) {
      widget.onChanged?.call(value);
    }
  }

  void _endSession() {
    if (!_inSession) return;
    _inSession = false;
    _states.update(WidgetState.dragged, false);
    widget.onChangeEnd?.call(widget.value);
  }

  void _emitKeyboard(double value) {
    final next = _snap(value);
    if (next != widget.value) widget.onChanged?.call(next);
  }

  Map<ShortcutActivator, Intent> _shortcuts(TextDirection direction) {
    final ltr = direction == TextDirection.ltr;
    const inc = _SliderIncrementIntent();
    const dec = _SliderDecrementIntent();
    return {
      const SingleActivator(LogicalKeyboardKey.arrowUp): inc,
      const SingleActivator(LogicalKeyboardKey.arrowDown): dec,
      const SingleActivator(LogicalKeyboardKey.arrowRight): ltr ? inc : dec,
      const SingleActivator(LogicalKeyboardKey.arrowLeft): ltr ? dec : inc,
      const SingleActivator(LogicalKeyboardKey.home): const _SliderMinIntent(),
      const SingleActivator(LogicalKeyboardKey.end): const _SliderMaxIntent(),
    };
  }

  Map<Type, Action<Intent>> get _actions => {
    _SliderIncrementIntent: CallbackAction<_SliderIncrementIntent>(
      onInvoke: (_) {
        _emitKeyboard(widget.value + _keyboardStep);
        return null;
      },
    ),
    _SliderDecrementIntent: CallbackAction<_SliderDecrementIntent>(
      onInvoke: (_) {
        _emitKeyboard(widget.value - _keyboardStep);
        return null;
      },
    ),
    _SliderMinIntent: CallbackAction<_SliderMinIntent>(
      onInvoke: (_) {
        _emitKeyboard(widget.min);
        return null;
      },
    ),
    _SliderMaxIntent: CallbackAction<_SliderMaxIntent>(
      onInvoke: (_) {
        _emitKeyboard(widget.max);
        return null;
      },
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final v = _apply(_resolve(theme), widget.style);
    final direction = Directionality.of(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget control = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? math.max(constraints.maxWidth, _minTrackWidth)
            : _minTrackWidth;
        final thumbStart = v.thumbSize / 2 + _fraction * (width - v.thumbSize);
        return SizedBox(
          key: _trackKey,
          height: _controlHeight,
          width: width,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrackPainter(
                    trackColor: v.trackColor,
                    rangeColor: v.rangeColor,
                    trackHeight: v.trackHeight,
                    thumbRadius: v.thumbSize / 2,
                    fraction: _fraction,
                    textDirection: direction,
                  ),
                ),
              ),
              PositionedDirectional(
                start: thumbStart - v.thumbSize / 2,
                top: (_controlHeight - v.thumbSize) / 2,
                child: _thumb(theme, v, reduceMotion: reduceMotion),
              ),
            ],
          ),
        );
      },
    );

    control = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _enabled ? (d) => _startSession(d.globalPosition) : null,
      onTapUp: _enabled ? (_) => _endSession() : null,
      onTapCancel: _enabled ? _endSession : null,
      onHorizontalDragStart: _enabled
          ? (d) => _startSession(d.globalPosition)
          : null,
      onHorizontalDragUpdate: _enabled
          ? (d) => _updateSession(d.globalPosition)
          : null,
      onHorizontalDragEnd: _enabled ? (_) => _endSession() : null,
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

    return Semantics(
      slider: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      value: _format(widget.value),
      increasedValue: _format(_snap(widget.value + _keyboardStep)),
      decreasedValue: _format(_snap(widget.value - _keyboardStep)),
      // Drop the action at the bound it cannot move past, so a screen reader
      // never announces an unchanged value at the min or max.
      onIncrease: _enabled && widget.value < widget.max
          ? () => _emitKeyboard(widget.value + _keyboardStep)
          : null,
      onDecrease: _enabled && widget.value > widget.min
          ? () => _emitKeyboard(widget.value - _keyboardStep)
          : null,
      child: control,
    );
  }

  String _format(double value) {
    final clamped = value.clamp(widget.min, widget.max);
    return clamped == clamped.roundToDouble()
        ? clamped.toStringAsFixed(0)
        : clamped.toStringAsFixed(2);
  }

  // The thumb: a white knob that carries the resting shadow and rim, drops both
  // on focus or drag, paints the focus ring on keyboard focus, and scales up
  // while dragging.
  Widget _thumb(
    FossThemeData theme,
    _SliderVisuals v, {
    required bool reduceMotion,
  }) {
    final colors = theme.colors;
    final dark = colors.isDark;
    return ListenableBuilder(
      listenable: _states,
      builder: (_, _) {
        final focused = _states.value.contains(WidgetState.focused);
        final dragging = _states.value.contains(WidgetState.dragged);
        final atRest = !focused && !dragging;

        Widget thumb = SizedBox.square(
          dimension: v.thumbSize,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: v.thumbColor,
              shape: CircleBorder(side: BorderSide(color: v.borderColor)),
              shadows: atRest ? v.shadow : const [],
            ),
          ),
        );

        if (atRest) {
          thumb = CustomPaint(
            foregroundPainter: const _RimPainter(color: _thumbRim),
            child: thumb,
          );
        }
        if (focused) {
          thumb = CustomPaint(
            foregroundPainter: _RingPainter(
              color: colors.ring.withValues(
                alpha: dark ? _ringAlphaDark : _ringAlphaLight,
              ),
            ),
            child: thumb,
          );
        }

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: dragging ? _dragScale : 1),
          duration: reduceMotion ? Duration.zero : _dragScaleDuration,
          curve: Curves.ease,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: thumb,
        );
      },
    );
  }
}

class _SliderIncrementIntent extends Intent {
  const _SliderIncrementIntent();
}

class _SliderDecrementIntent extends Intent {
  const _SliderDecrementIntent();
}

class _SliderMinIntent extends Intent {
  const _SliderMinIntent();
}

class _SliderMaxIntent extends Intent {
  const _SliderMaxIntent();
}

/// Builds the default appearance from the theme tokens.
_SliderVisuals _resolve(FossThemeData theme) {
  final c = theme.colors;
  return _SliderVisuals(
    trackColor: c.input,
    rangeColor: c.primary,
    thumbColor: _knobColor,
    borderColor: c.isDark ? c.background : c.input,
    shadow: theme.shadows.xs,
    trackHeight: _trackHeight,
    thumbSize: _thumbSize,
  );
}

/// Lays a per-instance [override] over the resolved [base], field by field.
_SliderVisuals _apply(_SliderVisuals base, FossSliderStyle? override) {
  if (override == null) return base;
  return _SliderVisuals(
    trackColor: override.trackColor ?? base.trackColor,
    rangeColor: override.rangeColor ?? base.rangeColor,
    thumbColor: override.thumbColor ?? base.thumbColor,
    borderColor: override.borderColor ?? base.borderColor,
    shadow: override.shadow ?? base.shadow,
    trackHeight: override.trackHeight ?? base.trackHeight,
    thumbSize: override.thumbSize ?? base.thumbSize,
  );
}

/// The fully resolved, non-null appearance. A [FossSliderStyle] override is
/// laid over it by [_apply], so the widget reads only non-null fields.
@immutable
class _SliderVisuals {
  const _SliderVisuals({
    required this.trackColor,
    required this.rangeColor,
    required this.thumbColor,
    required this.borderColor,
    required this.shadow,
    required this.trackHeight,
    required this.thumbSize,
  });

  final Color trackColor;
  final Color rangeColor;
  final Color thumbColor;
  final Color borderColor;
  final List<BoxShadow> shadow;
  final double trackHeight;
  final double thumbSize;
}

/// Paints the two stadium bars: the [trackColor] track inset at each end, and
/// the [rangeColor] filled range from the start to the thumb center. In RTL the
/// start is the right edge, so the fill grows leftward.
class _TrackPainter extends CustomPainter {
  const _TrackPainter({
    required this.trackColor,
    required this.rangeColor,
    required this.trackHeight,
    required this.thumbRadius,
    required this.fraction,
    required this.textDirection,
  });

  final Color trackColor;
  final Color rangeColor;
  final double trackHeight;
  final double thumbRadius;
  final double fraction;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final top = (size.height - trackHeight) / 2;
    final bottom = top + trackHeight;
    final radius = Radius.circular(trackHeight / 2);

    canvas.drawRRect(
      RRect.fromLTRBR(
        _trackInset,
        top,
        size.width - _trackInset,
        bottom,
        radius,
      ),
      Paint()..color = trackColor,
    );

    final ltr = textDirection == TextDirection.ltr;
    final fromStart = thumbRadius + fraction * (size.width - 2 * thumbRadius);
    final thumbX = ltr ? fromStart : size.width - fromStart;
    final startX = ltr ? _rangeMargin : size.width - _rangeMargin;

    canvas.drawRRect(
      RRect.fromLTRBR(
        math.min(startX, thumbX),
        top,
        math.max(startX, thumbX),
        bottom,
        radius,
      ),
      Paint()..color = rangeColor,
    );
  }

  @override
  bool shouldRepaint(_TrackPainter oldDelegate) =>
      oldDelegate.trackColor != trackColor ||
      oldDelegate.rangeColor != rangeColor ||
      oldDelegate.trackHeight != trackHeight ||
      oldDelegate.thumbRadius != thumbRadius ||
      oldDelegate.fraction != fraction ||
      oldDelegate.textDirection != textDirection;
}

/// Paints a 1px rim along the thumb's top inner edge, fading to nothing by the
/// center: a faint dark line that reads against the white knob.
class _RimPainter extends CustomPainter {
  const _RimPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(rect.center, rect.width / 2, paint);
  }

  // The thumb rim is a const painter, so the framework compares it by
  // identity and never calls this; kept to satisfy the interface.
  // coverage:ignore-start
  @override
  bool shouldRepaint(_RimPainter oldDelegate) => oldDelegate.color != color;
  // coverage:ignore-end
}

/// Paints the focus ring: a 3px circle concentric with the thumb, just outside
/// its edge.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      size.center(Offset.zero),
      size.width / 2 + _ringWidth / 2,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ringWidth,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.color != color;
}
