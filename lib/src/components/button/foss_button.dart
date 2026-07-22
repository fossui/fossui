import 'package:flutter/widgets.dart';
import 'package:fossui/src/components/spinner/foss_spinner.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_button_controller.dart';
part 'foss_button_painters.dart';
part 'foss_button_style.dart';

const double _iconSize = 18;
const double _iconOpacity = 0.8;
const double _disabledOpacity = 0.64;
const double _minTapTarget = 48;

/// Inner top-rim highlight on filled variants: 16% white at rest, 8% black when
/// pressed.
const Color _rimLight = Color(0x29FFFFFF);
const Color _rimPressed = Color(0x14000000);

/// The visual treatment of a [FossButton].
enum FossButtonVariant {
  /// Solid, high-emphasis primary action.
  primary,

  /// Subtle filled secondary action.
  secondary,

  /// Bordered, low-emphasis action on the surface.
  outline,

  /// Borderless, minimal action.
  ghost,

  /// Solid action for destructive operations.
  destructive,

  /// Borderless text action that underlines on interaction.
  link,
}

/// The size of a [FossButton].
enum FossButtonSize {
  /// Compact: 32 logical pixels tall.
  sm,

  /// Default: 36 logical pixels tall.
  md,

  /// Prominent: 40 logical pixels tall.
  lg,
}

/// {@category Inputs}
/// {@template foss.button.preview}
/// <img src="https://fossui.org/components/button/variants/light.png"
///   alt="FossButton variants, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/button/variants/dark.png"
///   alt="FossButton variants, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [button documentation ↗](https://fossui.org/docs/components/button) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/button/fossbutton/playground).
/// {@endtemplate}
///
/// A pressable button in the fossui style.
///
/// Pick a look with [variant] and a size with [size]; both read their colors,
/// radius, type, and spacing from `context.fossTheme`, so a global retheme
/// restyles every button. For a one-off, pass a [FossButtonStyle] to [style].
/// Passing a null [onPressed] disables the button.
///
/// [leading] and [trailing] take any widget (icon-agnostic); their color and
/// size are themed to match the label.
///
/// Loading and disabled can be set two ways. Declaratively: pass [loading] or a
/// null [onPressed]. Imperatively: pass a [FossButtonController] and drive it,
/// which toggles either state without rebuilding the button.
///
/// It does not guard against repeated taps: if [onPressed] runs an async
/// action, gate re-entrancy yourself or drive a [FossButtonController].
///
/// {@macro foss.customize}
///
/// Every size keeps a 48 logical-pixel minimum tap target, larger than its
/// visual height. [FossButton.icon] has no visible label, so it requires a
/// [semanticLabel].
///
/// See also [FossButtonStyle] for one-off overrides and [FossButtonController]
/// to drive loading and disabled imperatively.
///
/// ```dart
/// FossButton(
///   onPressed: () => save(),
///   loading: isSaving,
///   leading: const Icon(LucideIcons.check),
///   child: const Text('Save'),
/// );
/// ```
///
/// The [loading] flag swaps the label for a spinner. To keep a message beside
/// the spinner, compose it instead: put a [FossSpinner] in [leading] and pass a
/// null [onPressed] to disable.
///
/// ```dart
/// FossButton(
///   onPressed: null,
///   leading: const FossSpinner(size: 18),
///   child: const Text('Loading...'),
/// );
/// ```
class FossButton extends StatefulWidget {
  /// {@macro foss.button.preview}
  ///
  /// Creates a button. [child] is the label; a null [onPressed] disables it,
  /// and [loading] shows a spinner in place of the content.
  const FossButton({
    required this.child,
    this.onPressed,
    this.controller,
    this.variant = FossButtonVariant.primary,
    this.size = FossButtonSize.md,
    this.leading,
    this.trailing,
    this.style,
    this.semanticLabel,
    this.loading = false,
    this.loadingIndicator,
    super.key,
  }) : _iconOnly = false;

  /// {@macro foss.button.preview}
  ///
  /// Creates a square, icon-only button sized to its [size]. [icon] is the sole
  /// content and [semanticLabel] names the action for assistive tech, since
  /// there is no visible label.
  ///
  /// ```dart
  /// FossButton.icon(
  ///   onPressed: share,
  ///   semanticLabel: 'Share',
  ///   icon: const Icon(LucideIcons.share),
  /// );
  /// ```
  const FossButton.icon({
    required Widget icon,
    required this.semanticLabel,
    this.onPressed,
    this.controller,
    this.variant = FossButtonVariant.primary,
    this.size = FossButtonSize.md,
    this.style,
    this.loading = false,
    this.loadingIndicator,
    super.key,
  }) : child = icon,
       leading = null,
       trailing = null,
       _iconOnly = true;

  /// The label, typically a [Text].
  final Widget child;

  /// Called when the button is tapped or activated. Null disables the button.
  final VoidCallback? onPressed;

  /// Optional controller to drive loading and disabled imperatively, without
  /// rebuilding the button. You own it and must dispose it.
  final FossButtonController? controller;

  /// The visual treatment. Defaults to [FossButtonVariant.primary].
  final FossButtonVariant variant;

  /// The size. Defaults to [FossButtonSize.md].
  final FossButtonSize size;

  /// Optional widget before the label, themed as an icon.
  final Widget? leading;

  /// Optional widget after the label, themed as an icon.
  final Widget? trailing;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossButtonStyle? style;

  /// Accessibility label, for when [child] is not descriptive on its own.
  final String? semanticLabel;

  /// Whether the button shows a spinner and is non-interactive.
  final bool loading;

  /// Replaces the built-in spinner shown while [loading].
  final Widget? loadingIndicator;

  final bool _iconOnly;

  /// Whether the button shows its loading spinner: the [loading] flag is set,
  /// or the [controller] is in [FossButtonStatus.loading].
  bool get isLoading => loading || (controller?.isLoading ?? false);

  /// Whether the button is interactive. It must have an [onPressed], not be
  /// loading, and, if a [controller] is set, be in [FossButtonStatus.idle].
  bool get enabled {
    if (onPressed == null || isLoading) return false;
    return controller?.status != FossButtonStatus.disabled;
  }

  @override
  State<FossButton> createState() => _FossButtonState();
}

class _FossButtonState extends State<FossButton> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onControllerChanged);
    _syncDisabled();
  }

  @override
  void didUpdateWidget(FossButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }
    _syncDisabled();
  }

  void _onControllerChanged() => setState(_syncDisabled);

  void _syncDisabled() {
    final disabled = !widget.enabled;
    _states.update(WidgetState.disabled, disabled);
    // Disabling mid-press leaves the gesture without an up event; clear the
    // pressed bit so the button does not stay stuck in its pressed look.
    if (disabled) _states.update(WidgetState.pressed, false);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final visuals = _apply(
      _resolve(theme, widget.variant, widget.size, iconOnly: widget._iconOnly),
      widget.style,
    );
    final ring = theme.colors.ring;

    return Semantics(
      button: true,
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
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTapDown: widget.enabled
              ? (_) => _states.update(WidgetState.pressed, true)
              : null,
          onTapUp: widget.enabled
              ? (_) => _states.update(WidgetState.pressed, false)
              : null,
          onTapCancel: widget.enabled
              ? () => _states.update(WidgetState.pressed, false)
              : null,
          onTap: widget.enabled ? widget.onPressed : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: _minTapTarget,
              minHeight: _minTapTarget,
            ),
            child: Center(
              widthFactor: 1,
              child: ListenableBuilder(
                listenable: _states,
                builder: (context, _) => _paint(visuals, ring),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paint(_ButtonVisuals visuals, Color ring) {
    final states = _states.value;
    final fg = visuals.foreground.resolve(states);
    final pressed = states.contains(WidgetState.pressed);

    var child = _content(visuals, states, fg);
    if (widget.isLoading) {
      // Overlay a spinner; keep the content at zero opacity so width holds.
      child = Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0, child: child),
          widget.loadingIndicator ??
              FossSpinner(size: visuals.iconSize, color: fg),
        ],
      );
    }

    // Icon-only buttons are square: floor the width to the height.
    final minWidth = widget._iconOnly ? visuals.minHeight : 0.0;
    Widget surface = DecoratedBox(
      decoration: ShapeDecoration(
        color: visuals.background.resolve(states),
        shape: RoundedSuperellipseBorder(
          side: visuals.side,
          borderRadius: BorderRadius.circular(visuals.borderRadius),
        ),
        shadows: pressed || !widget.enabled ? const [] : visuals.shadow,
      ),
      child: Padding(
        padding: visuals.padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minWidth,
            minHeight: visuals.minHeight,
          ),
          child: child,
        ),
      ),
    );

    // Filled variants carry a 1px top-lit inner rim; pressed swaps it to a
    // faint dark line. Skipped when disabled, matching the resting elevation.
    if (widget.variant.isFilled && widget.enabled) {
      surface = CustomPaint(
        foregroundPainter: _TopHighlightPainter(
          color: pressed ? _rimPressed : _rimLight,
          radius: visuals.borderRadius,
        ),
        child: surface,
      );
    }

    if (!widget.enabled) {
      surface = Opacity(opacity: visuals.disabledOpacity, child: surface);
    }

    return CustomPaint(
      foregroundPainter: states.contains(WidgetState.focused)
          ? _FocusRingPainter(color: ring, radius: visuals.borderRadius)
          : null,
      child: surface,
    );
  }

  /// Builds the inner content: a single themed icon when icon-only, otherwise
  /// the leading / label / trailing row.
  Widget _content(_ButtonVisuals visuals, Set<WidgetState> states, Color fg) {
    final iconColor = fg.withValues(alpha: fg.a * _iconOpacity);
    final icon = IconThemeData(size: visuals.iconSize, color: iconColor);

    if (widget._iconOnly) {
      return IconTheme.merge(data: icon, child: widget.child);
    }

    final interacting =
        states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.hovered);
    final underline = widget.variant == FossButtonVariant.link && interacting;
    final leading = widget.leading;
    final trailing = widget.trailing;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: visuals.gap,
      children: [
        if (leading != null) IconTheme.merge(data: icon, child: leading),
        Flexible(
          child: DefaultTextStyle.merge(
            // Set the style outright (decoration too) so it renders the same
            // under any app, not only where an ancestor clears it.
            style: visuals.textStyle.copyWith(
              color: fg,
              decoration: underline
                  ? TextDecoration.underline
                  : TextDecoration.none,
            ),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            child: widget.child,
          ),
        ),
        if (trailing != null) IconTheme.merge(data: icon, child: trailing),
      ],
    );
  }
}

/// Solid-fill variants: they tint the drop shadow with their own color and
/// carry the top-lit inner rim. The single source for "is this filled".
extension on FossButtonVariant {
  bool get isFilled =>
      this == FossButtonVariant.primary ||
      this == FossButtonVariant.destructive;
}

/// Scales [color] to [opacity] of its own alpha, keeping it translucent so it
/// composites over whatever surface the button sits on at paint time. A fill
/// that stays translucent blends on the popover of a dialog or the fill of a
/// card, not just the app background.
Color _alpha(Color color, double opacity) =>
    color.withValues(alpha: color.a * opacity);

/// Composites [base] at [opacity] of its own alpha over a fixed [surface],
/// baking an opaque color at resolve time. Used only where the fill is already
/// opaque against a known surface.
Color _overlay(Color base, double opacity, Color surface) =>
    Color.alphaBlend(base.withValues(alpha: base.a * opacity), surface);

/// Recolors the [base] shadow layers to [color] at [alpha], keeping geometry.
/// Filled variants tint their drop shadow with their own fill, not flat black.
List<BoxShadow> _tint(List<BoxShadow> base, Color color, double alpha) => [
  for (final s in base)
    BoxShadow(
      color: color.withValues(alpha: alpha),
      offset: s.offset,
      blurRadius: s.blurRadius,
      spreadRadius: s.spreadRadius,
      blurStyle: s.blurStyle,
    ),
];

/// Builds the default appearance for a (variant, size) from the theme tokens.
_ButtonVisuals _resolve(
  FossThemeData theme,
  FossButtonVariant variant,
  FossButtonSize size, {
  required bool iconOnly,
}) {
  final c = theme.colors;

  final Color base;
  final Color hover;
  final Color pressed;
  final Color fg;
  final BorderSide side;
  switch (variant) {
    case FossButtonVariant.primary:
      base = c.primary;
      hover = _alpha(c.primary, 0.9);
      pressed = hover;
      fg = c.primaryForeground;
      side = BorderSide(color: c.primary);
    case FossButtonVariant.secondary:
      base = c.secondary;
      hover = _alpha(c.secondary, 0.9);
      pressed = _alpha(c.secondary, 0.8);
      fg = c.secondaryForeground;
      side = BorderSide.none;
    case FossButtonVariant.outline:
      // Dark mode fills with the input color (32% at rest, 64% interacting)
      // rather than the flat popover, so the surface reads lifted like a field.
      if (c.isDark) {
        base = _overlay(c.input, 0.32, c.background);
        hover = _overlay(c.input, 0.64, c.background);
      } else {
        base = c.popover;
        hover = _overlay(c.accent, 0.5, c.popover);
      }
      pressed = hover;
      fg = c.foreground;
      side = BorderSide(color: c.input);
    case FossButtonVariant.ghost:
      base = const Color(0x00000000);
      hover = c.accent;
      pressed = hover;
      fg = c.foreground;
      side = BorderSide.none;
    case FossButtonVariant.destructive:
      base = c.destructive;
      hover = _alpha(c.destructive, 0.9);
      pressed = hover;
      fg = c.destructiveForegroundOn;
      side = BorderSide(color: c.destructive);
    case FossButtonVariant.link:
      base = const Color(0x00000000);
      hover = base;
      pressed = base;
      fg = c.foreground;
      side = BorderSide.none;
  }

  // Filled variants tint the lift with their own fill; outline keeps the
  // neutral lift; the rest cast none.
  final shadow = switch (variant) {
    _ when variant.isFilled => _tint(theme.shadows.xs, base, 0.24),
    FossButtonVariant.outline => theme.shadows.xs,
    _ => FossShadows.none,
  };

  final (height, gap, horizontalPadding) = switch (size) {
    FossButtonSize.sm => (32.0, theme.spacing(1.5), theme.spacing(2.5)),
    FossButtonSize.md => (36.0, theme.spacing(2), theme.spacing(3)),
    FossButtonSize.lg => (40.0, theme.spacing(2), theme.spacing(3.5)),
  };

  return _ButtonVisuals(
    background: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) return pressed;
      if (states.contains(WidgetState.hovered)) return hover;
      return base;
    }),
    foreground: WidgetStatePropertyAll(fg),
    side: side,
    borderRadius: theme.radii.lg,
    // Icon-only buttons drop side padding; squareness is enforced at paint.
    padding: iconOnly
        ? EdgeInsets.zero
        : EdgeInsets.symmetric(horizontal: horizontalPadding),
    minHeight: height,
    textStyle: theme.typography.base.medium,
    shadow: shadow,
    iconSize: _iconSize,
    gap: gap,
    disabledOpacity: _disabledOpacity,
  );
}

/// The fully resolved, non-null appearance for one (variant, size). A public
/// [FossButtonStyle] override is laid over it by [_apply], so the widget reads
/// only non-null fields and never needs the null-assertion operator.
@immutable
class _ButtonVisuals {
  const _ButtonVisuals({
    required this.background,
    required this.foreground,
    required this.side,
    required this.borderRadius,
    required this.padding,
    required this.minHeight,
    required this.textStyle,
    required this.shadow,
    required this.iconSize,
    required this.gap,
    required this.disabledOpacity,
  });

  final WidgetStateProperty<Color> background;
  final WidgetStateProperty<Color> foreground;
  final BorderSide side;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double minHeight;
  final TextStyle textStyle;
  final List<BoxShadow> shadow;
  final double iconSize;
  final double gap;
  final double disabledOpacity;
}

/// Lays a per-instance [override] over the resolved [base], field by field.
_ButtonVisuals _apply(_ButtonVisuals base, FossButtonStyle? override) {
  if (override == null) return base;
  return _ButtonVisuals(
    background: override.backgroundColor ?? base.background,
    foreground: override.foregroundColor ?? base.foreground,
    side: override.side ?? base.side,
    borderRadius: override.borderRadius ?? base.borderRadius,
    padding: override.padding ?? base.padding,
    minHeight: override.minHeight ?? base.minHeight,
    textStyle: override.textStyle ?? base.textStyle,
    shadow: override.shadow ?? base.shadow,
    iconSize: override.iconSize ?? base.iconSize,
    gap: override.gap ?? base.gap,
    disabledOpacity: override.disabledOpacity ?? base.disabledOpacity,
  );
}
