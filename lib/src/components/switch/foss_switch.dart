import 'package:flutter/widgets.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_switch_style.dart';

// Fixed control geometry, mobile base. The track is a pill, the thumb a circle
// inset by the same gap on every side; the thumb travel falls out of the two
// (inner width minus the thumb), so it is never a separate literal.
const double _thumbSize = 20;
const double _trackWidth = 38;
const double _trackHeight = 22;

const double _disabledOpacity = 0.64;
const double _ringWidth = 2;
const double _ringOffset = 1;
const double _minTapTarget = 48;

// Pressed thumb squish: a small stretch along the travel axis from the leading
// edge, springing back on release.
const double _pressScaleX = 1.1;

// The thumb slides faster than the track crossfades; both are below the token
// set, so the slide and the squish are local widget constants. The crossfade
// reuses the overlay duration token.
const Duration _slideDuration = Duration(milliseconds: 150);
const Duration _squishDuration = Duration(milliseconds: 100);

/// An instant on / off toggle: a pill track with a sliding thumb that commits a
/// boolean the moment it is flipped.
///
/// The switch is controlled: it renders [value] and reports the toggled value
/// through [onChanged] on a tap, a drag, or Space / Enter. Passing `null` to
/// [onChanged] disables it (dims the control and drops the pointer), so there
/// is no separate enabled flag. It carries no visible label; lay out the row
/// around it and name it for assistive tech with [semanticsLabel].
///
/// Colors, the track crossfade, and the thumb come from `context.fossTheme`;
/// pass a [FossSwitchStyle] to [style] for a one-off.
///
/// ```dart
/// FossSwitch(
///   value: wifiOn,
///   semanticsLabel: 'Wi-Fi',
///   onChanged: (on) => setState(() => wifiOn = on),
/// );
/// ```
class FossSwitch extends StatefulWidget {
  /// Creates a switch showing [value].
  const FossSwitch({
    required this.value,
    this.onChanged,
    this.semanticsLabel,
    this.style,
    super.key,
  });

  /// The current state: `true` on, `false` off.
  final bool value;

  /// Called with the toggled value on a tap, drag, or Space / Enter. Null
  /// disables the switch.
  final ValueChanged<bool>? onChanged;

  /// Accessibility name for the toggle.
  final String? semanticsLabel;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossSwitchStyle? style;

  @override
  State<FossSwitch> createState() => _FossSwitchState();
}

class _FossSwitchState extends State<FossSwitch> {
  final WidgetStatesController _states = WidgetStatesController();

  bool get _enabled => widget.onChanged != null;

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  void _toggle() => widget.onChanged?.call(!widget.value);

  void _press(bool pressed) => _states.update(WidgetState.pressed, pressed);

  // A flick toggles toward its direction; a still release falls back to a plain
  // toggle. The pointer axis is mapped through the reading direction so a drag
  // to the visual end always means "on".
  void _dragEnd(DragEndDetails details, TextDirection direction) {
    _press(false);
    final velocity = details.primaryVelocity ?? 0;
    if (velocity == 0) {
      _toggle();
      return;
    }
    final toEnd = direction == TextDirection.ltr ? velocity > 0 : velocity < 0;
    if (toEnd != widget.value) widget.onChanged?.call(toEnd);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final v = _resolve(theme, widget.style);
    final direction = Directionality.of(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final on = widget.value;

    // Off rests at the leading edge, on at the trailing edge; the squish grows
    // from whichever edge the thumb sits against. Both mirror under RTL.
    final align = on
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;
    final pad = (v.trackHeight - v.thumbSize) / 2;

    Widget visual = ListenableBuilder(
      listenable: _states,
      builder: (context, child) {
        final focused = _states.value.contains(WidgetState.focused);
        final pressed = _states.value.contains(WidgetState.pressed);

        final squish = pressed && !reduceMotion ? _pressScaleX : 1.0;
        final thumb = TweenAnimationBuilder<double>(
          tween: Tween<double>(end: squish),
          duration: reduceMotion ? Duration.zero : _squishDuration,
          curve: Curves.ease,
          builder: (_, scale, thumbChild) => Transform(
            alignment: align.resolve(direction),
            transform: Matrix4.diagonal3Values(scale, 1, 1),
            child: thumbChild,
          ),
          child: SizedBox.square(
            dimension: v.thumbSize,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: v.thumbColor,
                shape: const CircleBorder(),
                shadows: v.shadow,
              ),
            ),
          ),
        );

        Widget track = TweenAnimationBuilder<double>(
          tween: Tween<double>(end: on ? 1 : 0),
          duration: reduceMotion ? Duration.zero : theme.motion.overlay,
          curve: Curves.ease,
          builder: (_, t, trackChild) => DecoratedBox(
            decoration: ShapeDecoration(
              color: Color.lerp(v.inactiveTrackColor, v.activeTrackColor, t),
              shape: const StadiumBorder(),
            ),
            child: trackChild,
          ),
          child: Padding(
            padding: EdgeInsets.all(pad),
            child: AnimatedAlign(
              alignment: align,
              duration: reduceMotion ? Duration.zero : _slideDuration,
              curve: Curves.ease,
              child: thumb,
            ),
          ),
        );

        if (focused) {
          track = CustomPaint(
            foregroundPainter: _RingPainter(
              color: theme.colors.ring,
              offsetColor: theme.colors.background,
            ),
            child: track,
          );
        }
        return track;
      },
    );

    visual = SizedBox(
      width: v.trackWidth,
      height: v.trackHeight,
      child: visual,
    );

    if (!_enabled) {
      visual = Opacity(opacity: _disabledOpacity, child: visual);
    }

    // The visible track is small; the gesture and focus target is floored to
    // the minimum tap size around it without enlarging the pill.
    final control = FocusableActionDetector(
      enabled: _enabled,
      mouseCursor: _enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onShowFocusHighlight: (value) =>
          _states.update(WidgetState.focused, value),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _toggle();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // The toggle role, state, and tap live on the outer Semantics node; the
        // drag handlers would otherwise leak scroll actions into the tree.
        excludeFromSemantics: true,
        onTap: _enabled ? _toggle : null,
        onTapDown: _enabled ? (_) => _press(true) : null,
        onTapUp: _enabled ? (_) => _press(false) : null,
        onTapCancel: _enabled ? () => _press(false) : null,
        onHorizontalDragStart: _enabled ? (_) => _press(true) : null,
        onHorizontalDragEnd: _enabled ? (d) => _dragEnd(d, direction) : null,
        onHorizontalDragCancel: _enabled ? () => _press(false) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: _minTapTarget,
            minHeight: _minTapTarget,
          ),
          child: Center(child: visual),
        ),
      ),
    );

    // One merged node carries the toggle role, its state, and the focus action
    // from the detector, so assistive tech announces the switch once.
    return MergeSemantics(
      child: Semantics(
        toggled: on,
        enabled: _enabled,
        label: widget.semanticsLabel,
        onTap: _enabled ? _toggle : null,
        child: control,
      ),
    );
  }
}

// The thumb wears the small shadow softened to a 5% tint, a faint lift rather
// than a drop shadow.
List<BoxShadow> _thumbShadow(List<BoxShadow> base) => <BoxShadow>[
  for (final shadow in base)
    shadow.copyWith(color: shadow.color.withValues(alpha: 0.05)),
];

/// Builds the default appearance from the theme tokens, then lays a
/// per-instance [override] over it field by field.
_SwitchVisuals _resolve(FossThemeData theme, FossSwitchStyle? override) {
  final c = theme.colors;
  return _SwitchVisuals(
    activeTrackColor: override?.activeTrackColor ?? c.primary,
    inactiveTrackColor: override?.inactiveTrackColor ?? c.input,
    thumbColor: override?.thumbColor ?? c.background,
    shadow: override?.shadow ?? _thumbShadow(theme.shadows.sm),
    trackWidth: override?.trackWidth ?? _trackWidth,
    trackHeight: override?.trackHeight ?? _trackHeight,
    thumbSize: override?.thumbSize ?? _thumbSize,
  );
}

/// The fully resolved, non-null appearance. A [FossSwitchStyle] override is
/// laid over it by [_resolve], so the widget reads only non-null fields.
@immutable
class _SwitchVisuals {
  const _SwitchVisuals({
    required this.activeTrackColor,
    required this.inactiveTrackColor,
    required this.thumbColor,
    required this.shadow,
    required this.trackWidth,
    required this.trackHeight,
    required this.thumbSize,
  });

  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final Color thumbColor;
  final List<BoxShadow> shadow;
  final double trackWidth;
  final double trackHeight;
  final double thumbSize;
}

/// Paints the focus ring: a stadium outset just past the track, with a 1px gap
/// (the offset) filled with [offsetColor] (the surface) so the ring reads as
/// detached from the track.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color, required this.offsetColor});

  final Color color;
  final Color offsetColor;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    RRect pill(double inflate) {
      final rect = box.inflate(inflate);
      return RRect.fromRectAndRadius(
        rect,
        Radius.circular(rect.shortestSide / 2),
      );
    }

    canvas
      ..drawRRect(
        pill(_ringOffset / 2),
        Paint()
          ..color = offsetColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringOffset,
      )
      ..drawRRect(
        pill(_ringOffset + _ringWidth / 2),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringWidth,
      );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color || old.offsetColor != offsetColor;
}
