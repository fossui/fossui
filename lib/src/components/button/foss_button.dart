import 'package:flutter/widgets.dart';
import 'package:foss_ui/src/components/spinner/foss_spinner.dart';
import 'package:foss_ui/src/theme/theme.dart';

part 'foss_button_controller.dart';
part 'foss_button_style.dart';

const double _iconSize = 18;
const double _iconOpacity = 0.8;
const double _disabledOpacity = 0.64;
const double _minTapTarget = 48;

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

/// A pressable button in the foss_ui style.
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
/// ```dart
/// FossButton(
///   onPressed: () => save(),
///   loading: isSaving,
///   leading: const Icon(LucideIcons.check),
///   child: const Text('Save'),
/// );
/// ```
class FossButton extends StatefulWidget {
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
  });

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
      _resolve(theme, widget.variant, widget.size),
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
            constraints: const BoxConstraints(minHeight: _minTapTarget),
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
    final iconColor = fg.withValues(alpha: fg.a * _iconOpacity);
    final shadow = states.contains(WidgetState.pressed)
        ? const <BoxShadow>[]
        : visuals.shadow;
    final leading = widget.leading;
    final trailing = widget.trailing;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: visuals.gap,
      children: [
        if (leading != null)
          IconTheme.merge(
            data: IconThemeData(size: visuals.iconSize, color: iconColor),
            child: leading,
          ),
        Flexible(
          child: DefaultTextStyle.merge(
            // Set the label style outright (decoration included) so it renders
            // the same under any app, not just where an ancestor clears it.
            style: visuals.textStyle.copyWith(
              color: fg,
              decoration: TextDecoration.none,
            ),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            child: widget.child,
          ),
        ),
        if (trailing != null)
          IconTheme.merge(
            data: IconThemeData(size: visuals.iconSize, color: iconColor),
            child: trailing,
          ),
      ],
    );

    if (widget.isLoading) {
      // Overlay a spinner; keep the content at zero opacity so width holds.
      content = Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0, child: content),
          widget.loadingIndicator ??
              FossSpinner(size: visuals.iconSize, color: fg),
        ],
      );
    }

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: visuals.background.resolve(states),
        borderRadius: BorderRadius.circular(visuals.borderRadius),
        border: visuals.side == BorderSide.none
            ? null
            : Border.fromBorderSide(visuals.side),
        boxShadow: shadow,
      ),
      child: Padding(
        padding: visuals.padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: visuals.minHeight),
          child: content,
        ),
      ),
    );

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
}

/// Composites [base] at [opacity] of its own alpha over [surface], baking the
/// translucent hover and pressed steps to opaque colors at resolve time.
Color _overlay(Color base, double opacity, Color surface) =>
    Color.alphaBlend(base.withValues(alpha: base.a * opacity), surface);

/// Builds the default appearance for a (variant, size) from the theme tokens.
_ButtonVisuals _resolve(
  FossThemeData theme,
  FossButtonVariant variant,
  FossButtonSize size,
) {
  final c = theme.colors;
  final surface = c.background;

  final Color base;
  final Color hover;
  final Color pressed;
  final Color fg;
  final BorderSide side;
  final List<BoxShadow> shadow;
  switch (variant) {
    case FossButtonVariant.primary:
      base = c.primary;
      hover = _overlay(c.primary, 0.9, surface);
      pressed = hover;
      fg = c.primaryForeground;
      side = BorderSide(color: c.primary);
      shadow = theme.shadows.xs;
    case FossButtonVariant.secondary:
      base = c.secondary;
      hover = _overlay(c.secondary, 0.9, surface);
      pressed = _overlay(c.secondary, 0.8, surface);
      fg = c.secondaryForeground;
      side = BorderSide.none;
      shadow = FossShadows.none;
    case FossButtonVariant.outline:
      base = c.popover;
      hover = _overlay(c.accent, 0.5, c.popover);
      pressed = hover;
      fg = c.foreground;
      side = BorderSide(color: c.input);
      shadow = theme.shadows.xs;
    case FossButtonVariant.ghost:
      base = const Color(0x00000000);
      hover = _overlay(c.accent, 1, surface);
      pressed = hover;
      fg = c.foreground;
      side = BorderSide.none;
      shadow = FossShadows.none;
    case FossButtonVariant.destructive:
      base = c.destructive;
      hover = _overlay(c.destructive, 0.9, surface);
      pressed = hover;
      fg = c.destructiveForegroundOn;
      side = BorderSide(color: c.destructive);
      shadow = theme.shadows.xs;
  }

  final double height;
  final double gap;
  final double horizontalPadding;
  switch (size) {
    case FossButtonSize.sm:
      height = 32;
      gap = theme.spacing(1.5);
      horizontalPadding = theme.spacing(2.5);
    case FossButtonSize.md:
      height = 36;
      gap = theme.spacing(2);
      horizontalPadding = theme.spacing(3);
    case FossButtonSize.lg:
      height = 40;
      gap = theme.spacing(2);
      horizontalPadding = theme.spacing(3.5);
  }

  return _ButtonVisuals(
    background: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) return pressed;
      if (states.contains(WidgetState.hovered)) return hover;
      return base;
    }),
    foreground: WidgetStatePropertyAll(fg),
    side: side,
    borderRadius: theme.radii.lg,
    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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

class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).inflate(2);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius + 2));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_FocusRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
