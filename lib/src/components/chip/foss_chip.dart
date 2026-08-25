import 'package:flutter/widgets.dart';
import 'package:fossui/src/foundation/foss_since.dart';
import 'package:fossui/src/icons/foss_glyph.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_chip_style.dart';

const double _affixOpacity = 0.8;
const double _disabledOpacity = 0.64;

/// Fill opacity of the soft hover step: the input color at 64%, composited so
/// it lands darker than the 4% rest fill in both themes.
const double _hoverFillOpacity = 0.64;

/// Fill opacity of a selected chip under the pointer.
const double _selectedHoverOpacity = 0.9;

const double _removeGlyphSize = 16;

const double _ringWidth = 2;
const double _ringOffset = 1;

/// Minimum tap target, so a compact chip stays comfortably tappable.
const double _minTapTarget = 48;

/// The visual treatment of a [FossChip].
enum FossChipVariant {
  /// Tinted fill, no border. The default.
  soft,

  /// Bordered surface that sits flat on the background.
  outline,
}

/// The size of a [FossChip].
enum FossChipSize {
  /// Compact: 24 logical pixels tall, sized to sit inside a field.
  sm,

  /// Default: 32 logical pixels tall, matching a small button.
  md,
}

/// {@category Inputs}
/// {@template foss.chip.preview}
/// <img src="https://fossui.org/components/chip/overview/light.png"
///   alt="FossChip, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/chip/overview/dark.png"
///   alt="FossChip, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [chip documentation ↗](https://fossui.org/docs/components/chip) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/chip/fosschip/playground).
/// {@endtemplate}
///
/// A compact pill carrying a value the user can pick or drop: a filter in a
/// bar, a tag on a record, an entry in a multi-select field.
///
/// The callbacks decide what it is. With neither it is a static tag. With
/// [onRemove] it grows a close affordance at the end. With [onSelected] the
/// body toggles [selected], and the chip fills with the primary color when on.
/// Both together give a filter chip that can also be dropped. Set [enabled] to
/// false to dim it and block both.
///
/// Selection is controlled: the chip renders [selected] and reports the flipped
/// value through [onSelected] on a tap or Space / Enter. Colors, radius, type,
/// and spacing come from `context.fossTheme`; pass a [FossChipStyle] to [style]
/// for a one-off.
///
/// {@macro foss.customize}
///
/// See also FossBadge for a static status pill, and FossToggle for a
/// button-shaped two-state control.
///
/// ```dart
/// FossChip(
///   label: const Text('Design'),
///   selected: isOn,
///   onSelected: (on) => setState(() => isOn = on),
///   onRemove: () => setState(() => tags.remove('Design')),
/// );
/// ```
@FossSince('0.1.2')
class FossChip extends StatefulWidget {
  /// {@macro foss.chip.preview}
  ///
  /// Creates a chip showing [label]. Passing [onSelected] makes the body
  /// selectable; passing [onRemove] adds the close affordance.
  const FossChip({
    required this.label,
    this.variant = FossChipVariant.soft,
    this.size = FossChipSize.md,
    this.leading,
    this.selected = false,
    this.onSelected,
    this.onRemove,
    this.removeLabel = 'Remove',
    this.enabled = true,
    this.semanticLabel,
    this.style,
    super.key,
  });

  /// The pill content, typically a [Text]. Color, weight, and type step are
  /// applied through `DefaultTextStyle`.
  final Widget label;

  /// The visual treatment. Defaults to [FossChipVariant.soft].
  final FossChipVariant variant;

  /// The size. Defaults to [FossChipSize.md].
  final FossChipSize size;

  /// Optional widget before the label, themed as an icon.
  final Widget? leading;

  /// Whether the chip reads as chosen. Only meaningful with [onSelected].
  final bool selected;

  /// Called with the flipped value when the body is tapped or activated. Null
  /// leaves the body inert.
  final ValueChanged<bool>? onSelected;

  /// Called when the close affordance is activated. Null hides it.
  final VoidCallback? onRemove;

  /// Accessibility name for the close affordance.
  final String removeLabel;

  /// Whether the chip responds to input. False dims it and blocks the body and
  /// the close affordance alike.
  final bool enabled;

  /// Accessibility name for the chip, when [label] does not carry the whole
  /// meaning. It replaces the label in the semantics tree rather than adding
  /// to it, so assistive technology announces one name.
  final String? semanticLabel;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossChipStyle? style;

  /// Whether the body toggles selection: it is enabled and has an
  /// [onSelected].
  bool get selectable => enabled && onSelected != null;

  @override
  State<FossChip> createState() => _FossChipState();
}

class _FossChipState extends State<FossChip> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(FossChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    _states
      ..update(WidgetState.selected, widget.selected)
      ..update(WidgetState.disabled, !widget.enabled);
  }

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  void _toggle() => widget.onSelected?.call(!widget.selected);

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final visuals = _resolve(
      theme,
      widget.variant,
      widget.size,
    ).merge(widget.style);

    Widget chip = ListenableBuilder(
      listenable: _states,
      builder: (context, _) => _paint(visuals),
    );

    if (widget.selectable) {
      chip = FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
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
          onTap: _toggle,
          // A selectable body is a tap target in its own right, so it floors at
          // the minimum. An inert body keeps its exact box, which is what lets
          // a field lay chips out without extra row height.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _minTapTarget),
            child: Center(widthFactor: 1, heightFactor: 1, child: chip),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      button: widget.selectable,
      toggled: widget.onSelected == null ? null : widget.selected,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: chip,
    );
  }

  Widget _paint(_ChipVisuals visuals) {
    final states = _states.value;
    final foreground = visuals.foreground.resolve(states);
    final remove = widget.onRemove;

    Widget surface = DecoratedBox(
      decoration: ShapeDecoration(
        color: visuals.background.resolve(states),
        shape: RoundedSuperellipseBorder(
          side: visuals.side.resolve(states),
          borderRadius: visuals.radius,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: visuals.minHeight),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: visuals.padStart,
                  // With a close affordance the button's own padding closes the
                  // end, and doubling up would push the glyph off the edge.
                  end: remove == null ? visuals.padEnd : 0,
                ),
                child: _content(visuals, foreground),
              ),
            ),
            if (remove != null)
              _RemoveButton(
                color: foreground,
                padding: visuals.removePadding,
                radius: visuals.removeRadius,
                ring: visuals.ring,
                ringOffset: visuals.ringOffset,
                label: widget.removeLabel,
                enabled: widget.enabled,
                onRemove: remove,
              ),
          ],
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

  /// Builds the leading icon and label row.
  Widget _content(_ChipVisuals visuals, Color foreground) {
    final leading = widget.leading;
    var label = DefaultTextStyle.merge(
      style: visuals.textStyle.copyWith(color: foreground),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      child: widget.label,
    );

    // A semanticLabel names the whole chip, so the visible text drops out of
    // the tree rather than being announced after it.
    if (widget.semanticLabel != null) {
      label = ExcludeSemantics(child: label);
    }

    if (leading == null) return label;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: visuals.gap,
      children: [
        ExcludeSemantics(
          child: IconTheme.merge(
            data: IconThemeData(
              size: visuals.iconSize,
              color: foreground.withValues(alpha: foreground.a * _affixOpacity),
            ),
            child: leading,
          ),
        ),
        Flexible(child: label),
      ],
    );
  }
}

/// The close affordance: its own focus stop, its own hover, and a hit region
/// grown past the small glyph without disturbing the chip's layout.
class _RemoveButton extends StatefulWidget {
  const _RemoveButton({
    required this.color,
    required this.padding,
    required this.radius,
    required this.ring,
    required this.ringOffset,
    required this.label,
    required this.enabled,
    required this.onRemove,
  });

  final Color color;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final Color ring;
  final Color ringOffset;
  final String label;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  State<_RemoveButton> createState() => _RemoveButtonState();
}

class _RemoveButtonState extends State<_RemoveButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final lit = _hovered || _focused;
    final color = widget.color.withValues(
      alpha: widget.color.a * (lit ? 1.0 : _affixOpacity),
    );

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        mouseCursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onRemove();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? widget.onRemove : null,
          child: Padding(
            padding: widget.padding,
            child: CustomPaint(
              foregroundPainter: _focused
                  ? _FocusRingPainter(
                      color: widget.ring,
                      offsetColor: widget.ringOffset,
                      radius: widget.radius,
                    )
                  : null,
              // Compact glyph footprint, hit region grown to the minimum touch
              // target so the small mark is comfortably tappable. The overflow
              // keeps that growth out of the chip's layout.
              child: SizedBox.square(
                dimension: _removeGlyphSize,
                child: OverflowBox(
                  maxWidth: _minTapTarget,
                  maxHeight: _minTapTarget,
                  child: Center(
                    child: CustomPaint(
                      size: const Size.square(_removeGlyphSize),
                      painter: CloseGlyph(color),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scales [color] to [opacity] of its own alpha, keeping it translucent so the
/// fill composites over whatever surface the chip sits on.
Color _alpha(Color color, double opacity) =>
    color.withValues(alpha: color.a * opacity);

/// Composites [base] at [opacity] of its own alpha over a fixed [surface],
/// baking an opaque color for the soft hover step.
Color _overlay(Color base, double opacity, Color surface) =>
    Color.alphaBlend(base.withValues(alpha: base.a * opacity), surface);

/// Builds the default appearance for a (variant, size) from the theme tokens.
_ChipVisuals _resolve(
  FossThemeData theme,
  FossChipVariant variant,
  FossChipSize size,
) {
  final c = theme.colors;

  final Color rest;
  final Color hover;
  final Color restForeground;
  final BorderSide side;
  switch (variant) {
    case FossChipVariant.soft:
      rest = c.accent;
      hover = _overlay(c.input, _hoverFillOpacity, c.background);
      restForeground = c.accentForeground;
      side = BorderSide.none;
    case FossChipVariant.outline:
      rest = c.background;
      hover = c.accent;
      restForeground = c.foreground;
      side = BorderSide(color: c.input);
  }

  // Selection collapses both variants to the same solid pill, so a chosen chip
  // reads the same wherever it sits.
  final selectedSide = switch (variant) {
    FossChipVariant.soft => BorderSide.none,
    FossChipVariant.outline => BorderSide(color: c.primary),
  };

  final (minHeight, padX, removePadX, removePadY, iconSize) = switch (size) {
    FossChipSize.sm => (
      24.0,
      theme.spacing(2),
      theme.spacing(1.5),
      theme.spacing(1),
      14.0,
    ),
    FossChipSize.md => (
      32.0,
      theme.spacing(2.5),
      theme.spacing(2),
      theme.spacing(2),
      16.0,
    ),
  };

  return _ChipVisuals(
    background: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return states.contains(WidgetState.hovered)
            ? _alpha(c.primary, _selectedHoverOpacity)
            : c.primary;
      }
      if (states.contains(WidgetState.hovered)) return hover;
      return rest;
    }),
    foreground: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? c.primaryForeground
          : restForeground,
    ),
    side: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected) ? selectedSide : side,
    ),
    radius: BorderRadius.all(Radius.circular(theme.radii.md)),
    removeRadius: BorderRadius.all(Radius.circular(theme.radii.sm)),
    padStart: padX,
    padEnd: padX,
    removePadding: EdgeInsets.symmetric(
      horizontal: removePadX,
      vertical: removePadY,
    ),
    minHeight: minHeight,
    textStyle: theme.typography.sm.medium,
    iconSize: iconSize,
    gap: theme.spacing(1),
    disabledOpacity: _disabledOpacity,
    ring: c.ring,
    ringOffset: c.background,
  );
}

/// The fully resolved, non-null appearance for one (variant, size). A public
/// [FossChipStyle] override is laid over it by [merge], so the widget reads
/// only non-null fields and never needs the null-assertion operator.
@immutable
class _ChipVisuals {
  const _ChipVisuals({
    required this.background,
    required this.foreground,
    required this.side,
    required this.radius,
    required this.removeRadius,
    required this.padStart,
    required this.padEnd,
    required this.removePadding,
    required this.minHeight,
    required this.textStyle,
    required this.iconSize,
    required this.gap,
    required this.disabledOpacity,
    required this.ring,
    required this.ringOffset,
  });

  final WidgetStateProperty<Color> background;
  final WidgetStateProperty<Color> foreground;
  final WidgetStateProperty<BorderSide> side;
  final BorderRadius radius;
  final BorderRadius removeRadius;
  final double padStart;
  final double padEnd;
  final EdgeInsetsGeometry removePadding;
  final double minHeight;
  final TextStyle textStyle;
  final double iconSize;
  final double gap;
  final double disabledOpacity;
  final Color ring;
  final Color ringOffset;

  /// Lays a per-instance [override] over this resolved base, field by field.
  _ChipVisuals merge(FossChipStyle? override) {
    if (override == null) return this;
    final uniform = override.borderRadius;
    final corners = uniform == null
        ? radius
        : BorderRadius.all(Radius.circular(uniform));
    return _ChipVisuals(
      background: override.backgroundColor ?? background,
      foreground: override.foregroundColor ?? foreground,
      side: switch (override.side) {
        final s? => WidgetStatePropertyAll(s),
        null => side,
      },
      radius: corners,
      removeRadius: removeRadius,
      padStart: override.padding ?? padStart,
      padEnd: override.padding ?? padEnd,
      removePadding: removePadding,
      minHeight: override.minHeight ?? minHeight,
      textStyle: override.textStyle ?? textStyle,
      iconSize: override.iconSize ?? iconSize,
      gap: override.gap ?? gap,
      disabledOpacity: override.disabledOpacity ?? disabledOpacity,
      ring: ring,
      ringOffset: ringOffset,
    );
  }
}

/// Paints the focus ring: a 2px superellipse outset just past the edge, with a
/// 1px offset gap filled with [offsetColor] (the surface) so the ring reads as
/// detached, matching the corner shape rather than a circular arc.
class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter({
    required this.color,
    required this.offsetColor,
    required this.radius,
  });

  final Color color;
  final Color offsetColor;
  final BorderRadius radius;

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
