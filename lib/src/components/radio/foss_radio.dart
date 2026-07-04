import 'package:flutter/widgets.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_radio_group.dart';
part 'foss_radio_style.dart';

const double _circleSize = 18;
const double _dotSize = 8;
const double _ringWidth = 2;
const double _ringOffset = 1;
const double _disabledOpacity = 0.64;
const double _minTapTarget = 48;

// Error border and ring alphas: the border deepens when the option is focused,
// the ring lifts in dark mode.
const double _errorBorderOpacity = 0.36;
const double _errorBorderFocusedOpacity = 0.64;
const double _errorRingOpacityLight = 0.48;
const double _errorRingOpacityDark = 0.24;

// Dark surfaces lift the unchecked fill by the input color at 32% of its alpha.
const double _darkFillOpacity = 0.32;

// Card variant: the checked card lifts its border to the primary role and tints
// its fill with the accent role.
const double _cardCheckedBorderOpacity = 0.48;
const double _cardCheckedFillOpacity = 0.5;

// Inner top-lit rim at rest: a faint dark line in light mode, a faint white
// highlight in dark mode.
const Color _rimLight = Color(0x0A000000);
const Color _rimDark = Color(0x0FFFFFFF);

/// A single option within a [FossRadioGroup].
///
/// Renders a circular control with an optional [label] and [description]. Reads
/// its checked, enabled, and invalid state from the enclosing [FossRadioGroup]
/// and reports a tap by calling the group's callback with [value]. A bare
/// circle (no [label]) is valid. Setting `enabled: false` disables this option;
/// disabling the group disables every option.
///
/// Must be placed under a [FossRadioGroup] of the same value type [T]. Colors,
/// type, and spacing come from `context.fossTheme`; pass a [FossRadioStyle] to
/// [style] for a one-off.
///
/// ```dart
/// FossRadio<String>(
///   value: 'yearly',
///   label: 'Yearly',
///   description: 'Two months free',
/// );
/// ```
class FossRadio<T> extends StatefulWidget {
  /// Creates a radio option. [value] identifies it within the group.
  const FossRadio({
    required this.value,
    this.label,
    this.description,
    this.enabled = true,
    this.style,
    super.key,
  });

  /// The value this option contributes to the group, compared by `==`.
  final T value;

  /// Optional title beside the circle.
  final String? label;

  /// Optional secondary line below the [label].
  final String? description;

  /// Whether this option accepts input. Disabled when false or when the group
  /// is disabled.
  final bool enabled;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossRadioStyle? style;

  @override
  State<FossRadio<T>> createState() => _FossRadioState<T>();
}

class _FossRadioState<T> extends State<FossRadio<T>> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final group = FossRadioGroupScope.of<T>(context);
    if (group == null) {
      throw FlutterError(
        'FossRadio<$T> must be placed inside a FossRadioGroup<$T>.',
      );
    }

    final checked = group.groupValue == widget.value;
    final enabled = widget.enabled && group.enabled;
    final hasError = group.hasError;
    final v = _apply(_resolve(theme), widget.style);

    void select() => group.onChanged?.call(widget.value);

    final card = group.variant == FossRadioGroupVariant.card;
    final hasText = widget.label != null || widget.description != null;
    Widget option = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: card ? MainAxisSize.max : MainAxisSize.min,
      spacing: v.gap,
      children: [
        _circleSlot(
          theme,
          v,
          checked: checked,
          hasError: hasError,
          enabled: enabled,
          hasText: hasText,
        ),
        if (hasText) Flexible(child: _texts(theme, v)),
      ],
    );

    if (card) {
      option = _card(theme, child: option, checked: checked);
    }
    if (!enabled) {
      option = Opacity(opacity: _disabledOpacity, child: option);
    }

    // One merged node carries the radio role plus the label and description
    // text, so assistive tech announces the option once, not twice.
    return MergeSemantics(
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: checked,
        enabled: enabled,
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onShowFocusHighlight: (value) =>
              _states.update(WidgetState.focused, value),
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                select();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? select : null,
            // The card supplies its own padded hit area; the plain option is
            // floored to the minimum tap target around its content.
            child: card
                ? option
                : ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: _minTapTarget,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      heightFactor: 1,
                      child: option,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // The circle, aligned to the first text line when a label or description is
  // present so it centers on the title rather than the whole text block.
  Widget _circleSlot(
    FossThemeData theme,
    _RadioVisuals v, {
    required bool checked,
    required bool hasError,
    required bool enabled,
    required bool hasText,
  }) {
    final circle = ListenableBuilder(
      listenable: _states,
      builder: (_, _) => _circle(
        theme,
        v,
        checked: checked,
        hasError: hasError,
        enabled: enabled,
      ),
    );
    if (!hasText) return circle;
    // Center on the first text line: the title when present, else the
    // description, so a description-only option still aligns.
    final firstLine = widget.label != null ? v.labelStyle : v.descriptionStyle;
    final line = (firstLine.fontSize ?? 16) * (firstLine.height ?? 1);
    return SizedBox(
      height: line,
      child: Center(widthFactor: 1, child: circle),
    );
  }

  Widget _circle(
    FossThemeData theme,
    _RadioVisuals v, {
    required bool checked,
    required bool hasError,
    required bool enabled,
  }) {
    final colors = theme.colors;
    final dark = colors.isDark;
    final focused = _states.value.contains(WidgetState.focused);
    final showBorder = !checked;

    // Border stays the resting input color except when invalid, where it
    // deepens and the focus ring switches to the destructive role.
    var borderColor = v.borderColor;
    var ringColor = focused ? colors.ring : null;
    if (hasError) {
      if (showBorder) {
        borderColor = colors.destructive.withValues(
          alpha: focused ? _errorBorderFocusedOpacity : _errorBorderOpacity,
        );
      }
      if (focused) {
        ringColor = colors.destructive.withValues(
          alpha: dark ? _errorRingOpacityDark : _errorRingOpacityLight,
        );
      }
    }

    // The resting shadow and inner rim drop when checked, invalid, or disabled.
    final atRest = !checked && !hasError && enabled;

    Widget circle = SizedBox.square(
      dimension: v.circleSize,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: checked ? v.checkedColor : v.uncheckedFill,
          shape: CircleBorder(
            side: showBorder ? BorderSide(color: borderColor) : BorderSide.none,
          ),
          shadows: atRest ? v.shadow : const [],
        ),
        child: checked
            ? Center(
                child: SizedBox.square(
                  dimension: v.dotSize,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: v.dotColor,
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );

    if (atRest) {
      circle = CustomPaint(
        foregroundPainter: _RimPainter(
          color: dark ? _rimDark : _rimLight,
          topLit: dark,
        ),
        child: circle,
      );
    }

    if (ringColor != null) {
      circle = CustomPaint(
        foregroundPainter: _RingPainter(
          color: ringColor,
          offsetColor: colors.background,
        ),
        child: circle,
      );
    }

    return circle;
  }

  Widget _texts(FossThemeData theme, _RadioVisuals v) {
    final colors = theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: theme.spacing(1.5),
      children: [
        if (widget.label case final label?)
          Text(label, style: v.labelStyle.copyWith(color: colors.foreground)),
        if (widget.description case final description?)
          Text(
            description,
            style: v.descriptionStyle.copyWith(color: colors.mutedForeground),
          ),
      ],
    );
  }

  // Wraps an option in the card surface: a bordered, padded box that lifts its
  // border and fill when checked. A min content height keeps the card past the
  // tap-target floor even for a single-line option.
  Widget _card(
    FossThemeData theme, {
    required Widget child,
    required bool checked,
  }) {
    final colors = theme.colors;
    return DecoratedBox(
      decoration: ShapeDecoration(
        // accent at 50% of its own alpha: the accent role
        // is already a faint translucent tint, so this is a barely-there wash,
        // not a half-opaque fill.
        color: checked
            ? colors.accent.withValues(
                alpha: colors.accent.a * _cardCheckedFillOpacity,
              )
            : null,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(
            color: checked
                ? colors.primary.withValues(alpha: _cardCheckedBorderOpacity)
                : colors.border,
          ),
          borderRadius: BorderRadius.circular(theme.radii.lg),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(theme.spacing(3)),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: theme.spacing(6)),
          child: child,
        ),
      ),
    );
  }
}

/// Builds the default appearance from the theme tokens. The checked and
/// unchecked fills are both resolved here; the widget picks between them.
_RadioVisuals _resolve(FossThemeData theme) {
  final c = theme.colors;

  // Dark adds a faint lift to the unchecked circle: the input color at 32% of
  // its alpha, composited to opaque. Light is the bare surface.
  final uncheckedFill = c.isDark
      ? Color.alphaBlend(
          c.input.withValues(alpha: c.input.a * _darkFillOpacity),
          c.background,
        )
      : c.background;

  return _RadioVisuals(
    uncheckedFill: uncheckedFill,
    checkedColor: c.primary,
    dotColor: c.primaryForeground,
    borderColor: c.input,
    shadow: theme.shadows.xs,
    circleSize: _circleSize,
    dotSize: _dotSize,
    gap: theme.spacing(2),
    labelStyle: theme.typography.base,
    descriptionStyle: theme.typography.xs,
  );
}

/// Lays a per-instance [override] over the resolved [base], field by field.
_RadioVisuals _apply(_RadioVisuals base, FossRadioStyle? override) {
  if (override == null) return base;
  return _RadioVisuals(
    uncheckedFill: override.backgroundColor ?? base.uncheckedFill,
    checkedColor: override.checkedColor ?? base.checkedColor,
    dotColor: override.dotColor ?? base.dotColor,
    borderColor: override.borderColor ?? base.borderColor,
    shadow: override.shadow ?? base.shadow,
    circleSize: override.circleSize ?? base.circleSize,
    dotSize: override.dotSize ?? base.dotSize,
    gap: override.gap ?? base.gap,
    labelStyle: override.labelStyle ?? base.labelStyle,
    descriptionStyle: override.descriptionStyle ?? base.descriptionStyle,
  );
}

/// The fully resolved, non-null appearance. A [FossRadioStyle] override is laid
/// over it by [_apply], so the widget reads only non-null fields and never
/// needs the null-assertion operator.
@immutable
class _RadioVisuals {
  const _RadioVisuals({
    required this.uncheckedFill,
    required this.checkedColor,
    required this.dotColor,
    required this.borderColor,
    required this.shadow,
    required this.circleSize,
    required this.dotSize,
    required this.gap,
    required this.labelStyle,
    required this.descriptionStyle,
  });

  final Color uncheckedFill;
  final Color checkedColor;
  final Color dotColor;
  final Color borderColor;
  final List<BoxShadow> shadow;
  final double circleSize;
  final double dotSize;
  final double gap;
  final TextStyle labelStyle;
  final TextStyle descriptionStyle;
}

/// Paints a 1px rim inside the circle: brightest along one edge, fading to
/// nothing by the center. [topLit] lights the top edge; otherwise the bottom.
class _RimPainter extends CustomPainter {
  const _RimPainter({required this.color, required this.topLit});

  final Color color;
  final bool topLit;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    final shader = LinearGradient(
      begin: topLit ? Alignment.topCenter : Alignment.bottomCenter,
      end: Alignment.center,
      colors: [color, color.withValues(alpha: 0)],
    ).createShader(rect);
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(rect.center, rect.width / 2, paint);
  }

  @override
  bool shouldRepaint(_RimPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.topLit != topLit;
}

/// Paints the focus ring: a circle outset just past the control edge, with a
/// 1px gap (the offset) matching the resting design. The gap is filled with
/// [offsetColor] (the surface) so the ring reads as detached even over a tinted
/// card.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color, required this.offsetColor});

  final Color color;
  final Color offsetColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final edge = size.width / 2;
    canvas
      ..drawCircle(
        center,
        edge + _ringOffset / 2,
        Paint()
          ..color = offsetColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringOffset,
      )
      ..drawCircle(
        center,
        edge + _ringOffset + _ringWidth / 2,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringWidth,
      );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.offsetColor != offsetColor;
}
