import 'package:flutter/widgets.dart';
import 'package:fossui/src/foundation/foss_since.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_toggle_style.dart';

const double _iconSize = 18;
const double _iconOpacity = 0.8;
const double _disabledOpacity = 0.64;

/// Fill opacity of the pressed (on) state: the input color at 64%.
const double _pressedFillOpacity = 0.64;

const double _ringWidth = 2;
const double _ringOffset = 1;

/// Minimum tap target, so a small toggle stays comfortably tappable without
/// growing its visual.
const double _minTapTarget = 44;

/// The visual treatment of a [FossToggle].
enum FossToggleVariant {
  /// Borderless: transparent at rest, filling on hover and when pressed.
  standard,

  /// Bordered surface that sits on the background and lifts with a shadow. The
  /// shadow flattens in the on-state, reading the toggle as pressed in.
  outline,
}

/// The size of a [FossToggle], sharing the FossButton-family metrics.
enum FossToggleSize {
  /// Compact: 32 logical pixels tall.
  sm,

  /// Default: 36 logical pixels tall.
  md,

  /// Prominent: 40 logical pixels tall.
  lg,
}

/// {@category Inputs}
/// {@template foss.toggle.preview}
/// <img src="https://fossui.org/components/toggle/overview/light.png"
///   alt="FossToggle, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/toggle/overview/dark.png"
///   alt="FossToggle, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [toggle documentation ↗](https://fossui.org/docs/components/toggle) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/toggle/fosstoggle/playground).
/// {@endtemplate}
///
/// A button that holds a two-state pressed look: tap it to turn it on, tap
/// again to release. It is the control behind a formatting button (bold,
/// italic) in a toolbar, sized and shaped like a FossButton but carrying a
/// binary on / off state.
///
/// The toggle is controlled: it renders [pressed] and reports the flipped value
/// through [onPressedChanged] on a tap or Space / Enter. Passing `null` to
/// [onPressedChanged] disables it (dims the control and drops the pointer), so
/// there is no separate enabled flag.
///
/// Renders a [child] label, a [leading] icon, or both; a null [child] makes a
/// square icon-only toggle, in which case name it for assistive tech with
/// [semanticLabel]. Colors, radius, type, and spacing come from
/// `context.fossTheme`; pass a [FossToggleStyle] to [style] for a one-off.
///
/// {@macro foss.customize}
///
/// See also FossButton for a momentary action, and FossToggleGroup for a
/// set of toggles bound to one selection.
///
/// ```dart
/// FossToggle(
///   pressed: isBold,
///   leading: const Icon(LucideIcons.bold),
///   semanticLabel: 'Bold',
///   onPressedChanged: (on) => setState(() => isBold = on),
///   child: const Text('Bold'),
/// );
/// ```
@FossSince('0.1.1')
class FossToggle extends StatefulWidget {
  /// {@macro foss.toggle.preview}
  ///
  /// Creates a toggle showing [pressed]. A null [onPressedChanged] disables it;
  /// a null [child] makes it a square icon-only toggle.
  const FossToggle({
    required this.pressed,
    this.onPressedChanged,
    this.variant = FossToggleVariant.standard,
    this.size = FossToggleSize.md,
    this.leading,
    this.child,
    this.semanticLabel,
    this.style,
    super.key,
  });

  /// The current state: `true` on (pressed), `false` off.
  final bool pressed;

  /// Called with the flipped value on a tap or Space / Enter. Null disables the
  /// toggle.
  final ValueChanged<bool>? onPressedChanged;

  /// The visual treatment. Defaults to [FossToggleVariant.standard].
  final FossToggleVariant variant;

  /// The size. Defaults to [FossToggleSize.md].
  final FossToggleSize size;

  /// Optional widget before the label, themed as an icon. When [child] is null
  /// it is the sole content of a square icon-only toggle.
  final Widget? leading;

  /// The label, typically a [Text]. Null makes a square icon-only toggle.
  final Widget? child;

  /// Accessibility name, required in spirit for an icon-only toggle where
  /// [child] is null.
  final String? semanticLabel;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossToggleStyle? style;

  /// Whether the toggle is interactive: it has an [onPressedChanged].
  bool get enabled => onPressedChanged != null;

  @override
  State<FossToggle> createState() => _FossToggleState();
}

class _FossToggleState extends State<FossToggle> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(FossToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    _states
      ..update(WidgetState.selected, widget.pressed)
      ..update(WidgetState.disabled, !widget.enabled);
  }

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  void _toggle() => widget.onPressedChanged?.call(!widget.pressed);

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final visuals = _resolve(theme, widget.variant, widget.size).merge(
      widget.style,
    );
    final iconOnly = widget.child == null;

    return Semantics(
      button: true,
      toggled: widget.pressed,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        mouseCursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (v) => _states.update(WidgetState.hovered, v),
        onShowFocusHighlight: (v) => _states.update(WidgetState.focused, v),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _toggle();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.enabled ? _toggle : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: _minTapTarget,
              minHeight: _minTapTarget,
            ),
            child: Center(
              widthFactor: 1,
              child: ListenableBuilder(
                listenable: _states,
                builder: (context, _) => _paint(visuals, iconOnly),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paint(_ToggleVisuals visuals, bool iconOnly) {
    final states = _states.value;
    final fg = visuals.foreground.resolve(states);
    final on = widget.pressed;

    // Icon-only toggles are square: floor the width to the height.
    final minWidth = iconOnly ? visuals.minHeight : 0.0;
    Widget surface = DecoratedBox(
      decoration: ShapeDecoration(
        color: visuals.background.resolve(states),
        shape: RoundedSuperellipseBorder(
          side: visuals.side,
          borderRadius: visuals.radius,
        ),
        // The lift drops when on or disabled, matching coss `shadow-none`.
        shadows: on || !widget.enabled ? const [] : visuals.shadow,
      ),
      child: Padding(
        padding: iconOnly ? EdgeInsets.zero : visuals.padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minWidth,
            minHeight: visuals.minHeight,
          ),
          child: _content(visuals, iconOnly, fg),
        ),
      ),
    );

    if (!widget.enabled) {
      surface = Opacity(opacity: visuals.disabledOpacity, child: surface);
    }

    return CustomPaint(
      foregroundPainter: states.contains(WidgetState.focused)
          ? _FocusRingPainter(
              color: visuals.ring,
              offsetColor: visuals.ringOffset,
              radius: visuals.radius,
            )
          : null,
      child: surface,
    );
  }

  /// Builds the inner content: a single themed icon when icon-only, otherwise
  /// the leading / label row.
  Widget _content(_ToggleVisuals visuals, bool iconOnly, Color fg) {
    final iconColor = fg.withValues(alpha: fg.a * _iconOpacity);
    final icon = IconThemeData(size: visuals.iconSize, color: iconColor);
    final leading = widget.leading;
    final child = widget.child;

    if (iconOnly || child == null) {
      return IconTheme.merge(
        data: icon,
        child: leading ?? const SizedBox.shrink(),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: visuals.gap,
      children: [
        if (leading != null) IconTheme.merge(data: icon, child: leading),
        Flexible(
          child: DefaultTextStyle.merge(
            style: visuals.textStyle.copyWith(color: fg),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Scales [color] to [opacity] of its own alpha, keeping it translucent so the
/// pressed fill composites over whatever surface the toggle sits on.
Color _alpha(Color color, double opacity) =>
    color.withValues(alpha: color.a * opacity);

/// Composites [base] at [opacity] of its own alpha over a fixed [surface],
/// baking an opaque color used for the dark outline lift.
Color _overlay(Color base, double opacity, Color surface) =>
    Color.alphaBlend(base.withValues(alpha: base.a * opacity), surface);

/// Builds the default appearance for a (variant, size) from the theme tokens.
_ToggleVisuals _resolve(
  FossThemeData theme,
  FossToggleVariant variant,
  FossToggleSize size,
) {
  final c = theme.colors;

  final Color rest;
  final Color hover;
  final Color pressedFill;
  final BorderSide side;
  final List<BoxShadow> shadow;
  switch (variant) {
    case FossToggleVariant.standard:
      rest = const Color(0x00000000);
      hover = c.accent;
      pressedFill = _alpha(c.input, _pressedFillOpacity);
      side = BorderSide.none;
      shadow = FossShadows.none;
    case FossToggleVariant.outline:
      // Dark mode lifts the surface with the input color; light rests on the
      // background and hovers to accent.
      if (c.isDark) {
        rest = _overlay(c.input, 0.32, c.background);
        hover = _overlay(c.input, 0.64, c.background);
        pressedFill = c.input;
      } else {
        rest = c.background;
        hover = c.accent;
        pressedFill = _alpha(c.input, _pressedFillOpacity);
      }
      side = BorderSide(color: c.input);
      shadow = theme.shadows.xs;
  }

  final (height, padX) = switch (size) {
    FossToggleSize.sm => (32.0, theme.spacing(1.5) - 1),
    FossToggleSize.md => (36.0, theme.spacing(2) - 1),
    FossToggleSize.lg => (40.0, theme.spacing(2.5) - 1),
  };

  return _ToggleVisuals(
    background: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return pressedFill;
      if (states.contains(WidgetState.hovered)) return hover;
      return rest;
    }),
    foreground: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? c.accentForeground
          : c.foreground,
    ),
    side: side,
    radius: BorderRadius.all(Radius.circular(theme.radii.lg)),
    padding: EdgeInsets.symmetric(horizontal: padX),
    minHeight: height,
    textStyle: theme.typography.base.medium,
    shadow: shadow,
    iconSize: _iconSize,
    gap: theme.spacing(1.5),
    disabledOpacity: _disabledOpacity,
    ring: c.ring,
    ringOffset: c.background,
  );
}

/// The fully resolved, non-null appearance for one (variant, size). A public
/// [FossToggleStyle] override is laid over it by [merge], so the widget reads
/// only non-null fields and never needs the null-assertion operator.
@immutable
class _ToggleVisuals {
  const _ToggleVisuals({
    required this.background,
    required this.foreground,
    required this.side,
    required this.radius,
    required this.padding,
    required this.minHeight,
    required this.textStyle,
    required this.shadow,
    required this.iconSize,
    required this.gap,
    required this.disabledOpacity,
    required this.ring,
    required this.ringOffset,
  });

  final WidgetStateProperty<Color> background;
  final WidgetStateProperty<Color> foreground;
  final BorderSide side;
  final BorderRadius radius;
  final EdgeInsetsGeometry padding;
  final double minHeight;
  final TextStyle textStyle;
  final List<BoxShadow> shadow;
  final double iconSize;
  final double gap;
  final double disabledOpacity;
  final Color ring;
  final Color ringOffset;

  /// Lays a per-instance [override] over this resolved base, field by field.
  _ToggleVisuals merge(FossToggleStyle? override) {
    if (override == null) return this;
    final uniform = override.borderRadius;
    return _ToggleVisuals(
      background: override.backgroundColor ?? background,
      foreground: override.foregroundColor ?? foreground,
      side: override.side ?? side,
      radius:
          override.cornerRadius ??
          (uniform != null
              ? BorderRadius.all(Radius.circular(uniform))
              : radius),
      padding: override.padding ?? padding,
      minHeight: override.minHeight ?? minHeight,
      textStyle: override.textStyle ?? textStyle,
      shadow: override.shadow ?? shadow,
      iconSize: override.iconSize ?? iconSize,
      gap: override.gap ?? gap,
      disabledOpacity: override.disabledOpacity ?? disabledOpacity,
      ring: ring,
      ringOffset: ringOffset,
    );
  }
}

/// Paints the focus ring: a 2px superellipse outset just past the toggle edge,
/// with a 1px offset gap filled with [offsetColor] (the surface) so the ring
/// reads as detached, matching the corner shape rather than a circular arc.
class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter({
    required this.color,
    required this.offsetColor,
    required this.radius,
  });

  final Color color;
  final Color offsetColor;
  final BorderRadius radius;

  // A square corner stays square in the ring; a rounded one grows with the
  // outset, so a segmented item's ring follows its own joined corners.
  RSuperellipse _shape(Rect box, double inflate, double grow) {
    Radius corner(Radius c) =>
        c == Radius.zero ? Radius.zero : Radius.circular(c.x + grow);
    return RSuperellipse.fromRectAndCorners(
      box.inflate(inflate),
      topLeft: corner(radius.topLeft),
      topRight: corner(radius.topRight),
      bottomLeft: corner(radius.bottomLeft),
      bottomRight: corner(radius.bottomRight),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    canvas
      ..drawRSuperellipse(
        _shape(box, _ringOffset / 2, _ringOffset / 2),
        Paint()
          ..color = offsetColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringOffset,
      )
      ..drawRSuperellipse(
        _shape(box, _ringOffset + _ringWidth / 2, _ringOffset + _ringWidth / 2),
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
